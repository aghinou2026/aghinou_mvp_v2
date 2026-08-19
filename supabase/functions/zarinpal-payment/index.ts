import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MERCHANT_ID = Deno.env.get("ZARINPAL_MERCHANT_ID")!;

// The public HTTPS URL of this function.
// Example:
// https://<project-ref>.supabase.co/functions/v1/zarinpal-payment
const FUNCTION_PUBLIC_URL =
  Deno.env.get("ZARINPAL_CALLBACK_URL") ??
  `${SUPABASE_URL}/functions/v1/zarinpal-payment`;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

// Aghinou base subscription: 35,000 Toman = 350,000 Rial.
const AMOUNT_RIAL = 350_000;

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

function html(title: string, message: string) {
  return new Response(
    `<!doctype html><html lang="fa" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title></head><body style="font-family:sans-serif;padding:32px">
<h2>${title}</h2><p>${message}</p>
<p>اکنون می‌توانید به برنامه آگهینو برگردید.</p>
</body></html>`,
    { headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

async function createPayment(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  const userClient = createClient(
    SUPABASE_URL,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) return json({ error: "Unauthorized" }, 401);

  const { data: payment, error: insertError } = await admin
    .from("payments")
    .insert({
      user_id: user.id,
      amount: AMOUNT_RIAL,
      plan: "base_monthly",
      status: "pending",
    })
    .select("id")
    .single();

  if (insertError) return json({ error: insertError.message }, 500);

  const callbackUrl =
    `${FUNCTION_PUBLIC_URL}?action=callback&payment_id=${encodeURIComponent(payment.id)}`;

  const requestBody = {
    merchant_id: MERCHANT_ID,
    amount: AMOUNT_RIAL,
    callback_url: callbackUrl,
    description: "اشتراک پایه ماهانه آگهینو",
    metadata: {
      email: user.email ?? "",
    },
  };

  const gatewayResponse = await fetch(
    "https://api.zarinpal.com/pg/v4/payment/request.json",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
    },
  );

  const gateway = await gatewayResponse.json();

  if (!gatewayResponse.ok || gateway?.data?.code !== 100) {
    await admin.from("payments").update({
      status: "failed",
    }).eq("id", payment.id);

    return json({
      error: gateway?.errors?.message ?? "خطا در ایجاد تراکنش زرین‌پال",
      gateway,
    }, 502);
  }

  const authority = gateway.data.authority;

  const { error: updateError } = await admin
    .from("payments")
    .update({ authority })
    .eq("id", payment.id);

  if (updateError) return json({ error: updateError.message }, 500);

  return json({
    payment_id: payment.id,
    authority,
    payment_url: `https://www.zarinpal.com/pg/StartPay/${authority}`,
  });
}

async function verifyPayment(url: URL) {
  const paymentId = url.searchParams.get("payment_id");
  const authority = url.searchParams.get("Authority");
  const status = url.searchParams.get("Status");

  if (!paymentId || !authority) {
    return html("پرداخت نامعتبر", "اطلاعات بازگشت پرداخت کامل نیست.");
  }

  const { data: payment, error: paymentError } = await admin
    .from("payments")
    .select("id,user_id,amount,authority,status")
    .eq("id", paymentId)
    .single();

  if (paymentError || !payment) {
    return html("پرداخت پیدا نشد", "تراکنش موردنظر در آگهینو پیدا نشد.");
  }

  if (payment.status === "paid") {
    return html("پرداخت قبلاً تأیید شده", "این پرداخت قبلاً با موفقیت تأیید شده است.");
  }

  if (status !== "OK") {
    await admin.from("payments").update({
      status: "cancelled",
    }).eq("id", payment.id);

    return html("پرداخت لغو شد", "پرداخت توسط کاربر تکمیل نشد.");
  }

  const verifyResponse = await fetch(
    "https://api.zarinpal.com/pg/v4/payment/verify.json",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        merchant_id: MERCHANT_ID,
        amount: payment.amount,
        authority,
      }),
    },
  );

  const verify = await verifyResponse.json();
  const code = verify?.data?.code;
  const refId = verify?.data?.ref_id ?? null;

  if (!verifyResponse.ok || (code !== 100 && code !== 101)) {
    await admin.from("payments").update({
      status: "failed",
    }).eq("id", payment.id);

    return html(
      "پرداخت تأیید نشد",
      verify?.errors?.message ?? "تأیید تراکنش توسط درگاه ناموفق بود.",
    );
  }

  const expires = new Date();
  expires.setMonth(expires.getMonth() + 1);

  await admin.from("payments").update({
    status: "paid",
    ref_id: refId,
    paid_at: new Date().toISOString(),
    subscription_expires_at: expires.toISOString(),
  }).eq("id", payment.id);

  return html(
    "پرداخت موفق ✅",
    `اشتراک پایه آگهینو فعال شد. شماره پیگیری: ${refId ?? "ثبت شد"}`,
  );
}

Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);

    if (req.method === "GET" && url.searchParams.get("action") === "callback") {
      return await verifyPayment(url);
    }

    if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      if (body.action === "create") {
        return await createPayment(req);
      }
    }

    return json({ error: "Not found" }, 404);
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});
