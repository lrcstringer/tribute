/**
 * In-App Purchase validation + subscription webhook handlers.
 *
 * Exports:
 *   validateReceipt    — HTTPS callable; validates Apple/Google receipt and writes
 *                        subscription status to Firestore users/{uid}/subscription/status
 *   appleNotification  — HTTPS endpoint; receives Apple Server Notifications (v2)
 *   googleNotification — Pub/Sub trigger; receives Google Play Real-Time Developer Notifications
 *
 * Deployment note: deploy only this function:
 *   firebase deploy --only functions:validateReceipt
 *   firebase deploy --only functions:appleNotification
 *   firebase deploy --only functions:googleNotification
 *
 * Required environment config (set via Firebase Secret Manager or .env.local):
 *   APPLE_SHARED_SECRET   — App-specific shared secret from App Store Connect
 *   GOOGLE_SERVICE_ACCOUNT_JSON — Service account with Google Play Developer API access
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onRequest } from 'firebase-functions/v2/https';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { Timestamp } from 'firebase-admin/firestore';
import * as https from 'https';
import { GoogleAuth } from 'google-auth-library';

// ── Types ─────────────────────────────────────────────────────────────────────

interface ValidateReceiptPayload {
  platform: 'ios' | 'android';
  // iOS: base64-encoded App Store receipt
  receiptData?: string;
  // Android: purchase token from the Play Billing library
  purchaseToken?: string;
  productId: string;
}

interface SubscriptionStatus {
  productId: string;
  platform: 'ios' | 'android';
  purchaseId: string;
  status: 'active' | 'expired' | 'cancelled';
  expiresAt: Timestamp | null;
  validatedAt: Timestamp;
}

const PRODUCT_IDS = new Set([
  'tribute_premium_monthly',
  'tribute_premium_annual',
  'tribute_premium_lifetime',
]);

// ── validateReceipt (HTTPS Callable) ─────────────────────────────────────────

export const validateReceipt = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }
    const uid = request.auth.uid;
    const data = request.data as ValidateReceiptPayload;

    if (!data.platform || !data.productId) {
      throw new HttpsError('invalid-argument', 'platform and productId are required');
    }
    if (!PRODUCT_IDS.has(data.productId)) {
      throw new HttpsError('invalid-argument', `Unknown productId: ${data.productId}`);
    }

    let status: SubscriptionStatus;

    if (data.platform === 'ios') {
      if (!data.receiptData) throw new HttpsError('invalid-argument', 'receiptData required for iOS');
      status = await validateAppleReceipt(uid, data.receiptData, data.productId);
    } else {
      if (!data.purchaseToken) throw new HttpsError('invalid-argument', 'purchaseToken required for Android');
      status = await validateGooglePurchase(uid, data.purchaseToken, data.productId);
    }

    await writeSubscriptionStatus(uid, status);
    return { isPremium: status.status === 'active' };
  }
);

// ── Apple receipt validation ──────────────────────────────────────────────────

async function validateAppleReceipt(
  uid: string,
  receiptData: string,
  productId: string
): Promise<SubscriptionStatus> {
  const sharedSecret = process.env.APPLE_SHARED_SECRET ?? '';

  // Try production first, then sandbox on 21007 (sandbox receipt used in production)
  let result = await callAppleVerifyReceipt(receiptData, sharedSecret, false);
  if (result.status === 21007) {
    result = await callAppleVerifyReceipt(receiptData, sharedSecret, true);
  }

  if (result.status !== 0) {
    throw new HttpsError('failed-precondition', `Apple receipt validation failed: status ${result.status}`);
  }

  const isLifetime = productId === 'tribute_premium_lifetime';

  // Find the latest receipt for this product
  const latestReceipts: AppleLatestReceiptInfo[] = result.latest_receipt_info ?? [];
  const matching = latestReceipts
    .filter((r) => r.product_id === productId)
    .sort((a, b) => parseInt(b.purchase_date_ms) - parseInt(a.purchase_date_ms));

  if (matching.length === 0 && !isLifetime) {
    return {
      productId,
      platform: 'ios',
      purchaseId: '',
      status: 'expired',
      expiresAt: null,
      validatedAt: Timestamp.now(),
    };
  }

  const latest = matching[0];
  const isActive = isLifetime
    ? true
    : latest?.expires_date_ms
    ? parseInt(latest.expires_date_ms) > Date.now()
    : false;

  const expiresAt = isLifetime
    ? null
    : latest?.expires_date_ms
    ? Timestamp.fromMillis(parseInt(latest.expires_date_ms))
    : null;

  return {
    productId,
    platform: 'ios',
    purchaseId: latest?.transaction_id ?? '',
    status: isActive ? 'active' : 'expired',
    expiresAt,
    validatedAt: Timestamp.now(),
  };
}

interface AppleVerifyResponse {
  status: number;
  latest_receipt_info?: AppleLatestReceiptInfo[];
}

interface AppleLatestReceiptInfo {
  product_id: string;
  transaction_id: string;
  expires_date_ms?: string;
  purchase_date_ms: string;
}

function callAppleVerifyReceipt(
  receiptData: string,
  sharedSecret: string,
  sandbox: boolean
): Promise<AppleVerifyResponse> {
  const host = sandbox
    ? 'sandbox.itunes.apple.com'
    : 'buy.itunes.apple.com';

  const body = JSON.stringify({
    'receipt-data': receiptData,
    password: sharedSecret,
    'exclude-old-transactions': true,
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      { hostname: host, path: '/verifyReceipt', method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) } },
      (res) => {
        let data = '';
        res.on('data', (chunk: string) => (data += chunk));
        res.on('end', () => {
          try { resolve(JSON.parse(data)); }
          catch (e) { reject(e); }
        });
      }
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Google purchase validation ────────────────────────────────────────────────

async function validateGooglePurchase(
  uid: string,
  purchaseToken: string,
  productId: string
): Promise<SubscriptionStatus> {
  // To validate Google purchases server-side you need the Google Play Developer API.
  // Required: service account with "Google Play Android Developer" role.
  // Package name comes from the app's applicationId.
  const packageName = 'com.tributeapp.tribute';
  const isLifetime = productId === 'tribute_premium_lifetime';

  // For subscriptions (monthly/annual) use purchases.subscriptions.get
  // For one-time (lifetime) use purchases.products.get
  const accessToken = await getGoogleAccessToken();

  const apiBase = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
  const path = isLifetime
    ? `${apiBase}/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`
    : `${apiBase}/${packageName}/purchases/subscriptions/${productId}/tokens/${purchaseToken}`;

  const result = await fetchJson(path, accessToken);

  if (isLifetime) {
    const active = result.purchaseState === 0; // 0 = purchased
    return {
      productId,
      platform: 'android',
      purchaseId: purchaseToken,
      status: active ? 'active' : 'cancelled',
      expiresAt: null,
      validatedAt: Timestamp.now(),
    };
  }

  // Subscription
  const expiryMs = result.expiryTimeMillis ? parseInt(result.expiryTimeMillis as string) : 0;
  const isActive = expiryMs > Date.now() && result.paymentState !== 0; // paymentState 0 = pending

  return {
    productId,
    platform: 'android',
    purchaseId: purchaseToken,
    status: isActive ? 'active' : 'expired',
    expiresAt: expiryMs > 0 ? Timestamp.fromMillis(expiryMs) : null,
    validatedAt: Timestamp.now(),
  };
}

async function getGoogleAccessToken(): Promise<string> {
  const serviceAccountJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON not configured');

  const credentials = JSON.parse(serviceAccountJson);
  const auth = new GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  if (!tokenResponse.token) throw new Error('Failed to obtain Google access token');
  return tokenResponse.token;
}

function fetchJson(url: string, bearerToken: string): Promise<Record<string, unknown>> {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'GET',
      headers: { Authorization: `Bearer ${bearerToken}` },
    }, (res) => {
      let data = '';
      res.on('data', (chunk: string) => (data += chunk));
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

// ── Write subscription to Firestore ──────────────────────────────────────────

async function writeSubscriptionStatus(uid: string, status: SubscriptionStatus): Promise<void> {
  await admin.firestore()
    .collection('users').doc(uid)
    .collection('subscription').doc('status')
    .set(status);
}

// ── Apple Server Notifications (v2) ──────────────────────────────────────────

export const appleNotification = onRequest(
  { region: 'us-central1' },
  async (req, res) => {
    // Apple sends a signed JWT (signedPayload). In production:
    //   1. Decode the JWS and verify the Apple certificate chain
    //   2. Parse the notification type (SUBSCRIBED, DID_RENEW, EXPIRED, etc.)
    //   3. Look up the uid by originalTransactionId stored in Firestore
    //   4. Update users/{uid}/subscription/status accordingly
    //
    // Stub implementation — acknowledges receipt without processing.
    // TODO: implement full JWS verification and event handling before launch.
    console.log('Apple notification received (stub):', req.body);
    res.status(200).send('OK');
  }
);

// ── Google Play Real-Time Developer Notifications (Pub/Sub) ──────────────────

export const googleNotification = onMessagePublished(
  { topic: 'play-billing-notifications', region: 'us-central1' },
  async (event) => {
    // Google sends base64-encoded JSON in event.data.message.data.
    // Parse the DeveloperNotification, look up the purchase token, re-validate.
    //
    // Stub implementation — logs and acknowledges.
    // TODO: implement full notification handling before Android launch.
    const raw = event.data.message.data
      ? Buffer.from(event.data.message.data, 'base64').toString()
      : '{}';
    console.log('Google Play notification received (stub):', raw);
  }
);
