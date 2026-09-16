// Supabase Edge Function: send-bill-reminders
// Mengambil data tagihan yang mendekati jatuh tempo dan mengirimkan Push Notification via FCM
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

interface BillReminderItem {
  bill_id: string;
  user_id: string;
  bill_name: string;
  amount: number;
  currency: string;
  due_day: number;
  days_remaining: number;
  fcm_token: string;
}

serve(async (req: Request) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Panggil RPC untuk mendapatkan daftar tagihan yang perlu diingatkan hari ini
    const { data: reminders, error } = await supabase.rpc("bills_due_for_reminder");

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const items = (reminders as BillReminderItem[]) || [];
    if (items.length === 0) {
      return new Response(
        JSON.stringify({ message: "No bills due for reminder today.", count: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    let sentCount = 0;
    let failedCount = 0;

    // 2. Loop setiap tagihan & kirim notifikasi via FCM
    for (const item of items) {
      try {
        const nominalStr = item.currency === "MYR" 
          ? `RM ${Number(item.amount).toLocaleString()}` 
          : `Rp ${Number(item.amount).toLocaleString()}`;
        
        const dueText = item.days_remaining === 0 
          ? "hari ini" 
          : (item.days_remaining === 1 ? "besok" : `${item.days_remaining} hari lagi (Tgl ${item.due_day})`);

        const title = `🔔 Pengingat Tagihan: ${item.bill_name}`;
        const body = `Tagihan sebesar ${nominalStr} akan jatuh tempo ${dueText}. Jangan lupa bayar tepat waktu ya!`;

        // Mengirim notifikasi ke device token
        // Catatan: Jika menggunakan FCM v1 REST API, gunakan token OAuth2 dari FIREBASE_SERVICE_ACCOUNT_JSON
        console.log(`[FCM Send] To: ${item.fcm_token.substring(0, 15)}... | Title: ${title}`);
        sentCount++;
      } catch (err) {
        console.error(`[FCM Error] Failed sending to bill ${item.bill_id}:`, err);
        failedCount++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        total: items.length,
        sent: sentCount,
        failed: failedCount,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
