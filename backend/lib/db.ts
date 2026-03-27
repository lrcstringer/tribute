const DB_ENDPOINT = process.env.EXPO_PUBLIC_RORK_DB_ENDPOINT || "";
const DB_TOKEN = process.env.EXPO_PUBLIC_RORK_DB_TOKEN || "";
const DB_NAMESPACE = process.env.EXPO_PUBLIC_RORK_DB_NAMESPACE || "default";

async function dbFetch(path: string, options?: RequestInit): Promise<Response> {
  const url = `${DB_ENDPOINT}/${DB_NAMESPACE}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${DB_TOKEN}`,
      ...options?.headers,
    },
  });
  return res;
}

export async function dbGet<T>(key: string): Promise<T | null> {
  try {
    const res = await dbFetch(`/key/${encodeURIComponent(key)}`);
    if (!res.ok) return null;
    const data = await res.json();
    return (data?.value ?? data) as T;
  } catch {
    return null;
  }
}

export async function dbSet<T>(key: string, value: T): Promise<void> {
  await dbFetch(`/key/${encodeURIComponent(key)}`, {
    method: "PUT",
    body: JSON.stringify({ value }),
  });
}

export async function dbDelete(key: string): Promise<void> {
  await dbFetch(`/key/${encodeURIComponent(key)}`, {
    method: "DELETE",
  });
}

export async function dbList(prefix: string): Promise<string[]> {
  try {
    const res = await dbFetch(`/keys?prefix=${encodeURIComponent(prefix)}`);
    if (!res.ok) return [];
    const data = await res.json();
    return (data?.keys ?? data ?? []) as string[];
  } catch {
    return [];
  }
}
