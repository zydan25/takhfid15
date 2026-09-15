import { sendOtpApi, verifyOtpApi, type VerifySessionResponse } from './api';

export interface SendOtpResponse {
  success: boolean;
  phoneNumber: string;
  expiresInSeconds: number;
  retryAfterSeconds: number;
}

export type VerifyOtpResponse = VerifySessionResponse;

export async function sendWhatsAppOtp(payload: { phoneNumber: string }): Promise<{ data: SendOtpResponse }> {
  const data = await sendOtpApi(payload.phoneNumber);
  return { data };
}

export async function verifyWhatsAppOtp(payload: {
  phoneNumber: string;
  otp: string;
  firstName: string;
  secondName?: string;
  thirdName?: string;
  lastName?: string;
  governorate: string;
}): Promise<{ data: VerifyOtpResponse }> {
  const data = await verifyOtpApi(payload);
  return { data };
}
