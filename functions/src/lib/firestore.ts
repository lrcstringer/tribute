import { db } from './admin';
import { Timestamp } from 'firebase-admin/firestore';

export const usersCol = () => db.collection('users');
export const inviteCodesCol = () => db.collection('inviteCodes');
export const circlesCol = () => db.collection('circles');
export const membersCol = (circleId: string) => db.collection(`circles/${circleId}/members`);
export const gratitudesCol = (circleId: string) => db.collection(`circles/${circleId}/gratitudes`);
export const sosRequestsCol = (circleId: string) => db.collection(`circles/${circleId}/sosRequests`);
export const heatmapEntriesCol = (circleId: string) => db.collection(`circles/${circleId}/heatmapEntries`);
export const milestonesCol = (circleId: string) => db.collection(`circles/${circleId}/milestones`);
export const metaDoc = (circleId: string) => db.doc(`circles/${circleId}/meta/totals`);
export const userSeenGratitudeDoc = (circleId: string, userId: string) =>
  db.doc(`circles/${circleId}/userSeenGratitude/${userId}`);
export const sosContactsDoc = (circleId: string, userId: string) =>
  db.doc(`circles/${circleId}/sosContacts/${userId}`);

export { Timestamp, db };
