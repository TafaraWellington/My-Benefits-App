import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

export async function POST(request: Request) {
  try {
    const signature = request.headers.get('x-paystack-signature');
    if (!signature) {
      return NextResponse.json({ error: 'Signature header missing' }, { status: 400 });
    }

    const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
    if (!paystackSecret) {
      return NextResponse.json({ error: 'Server key not configured' }, { status: 500 });
    }

    // Read the raw body as text for signature verification
    const rawBody = await request.text();

    // Verify signature using HMAC SHA512
    const computedHash = crypto
      .createHmac('sha512', paystackSecret)
      .update(rawBody)
      .digest('hex');

    if (computedHash !== signature) {
      console.warn('Webhook Signature Verification Failed!');
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }

    const payload = JSON.parse(rawBody);

    // Only process charge.success event
    if (payload.event === 'charge.success') {
      const data = payload.data;
      const metadata = data.metadata;

      if (!metadata || !metadata.userId) {
        console.warn('Webhook charge.success received but metadata.userId is missing', data.reference);
        return NextResponse.json({ message: 'No metadata or userId, ignored' }, { status: 200 });
      }

      const { userId, credits, tier } = metadata;
      const amountPaid = data.amount / 100; // Convert to principal currency

      console.log(`Processing successful payment of R${amountPaid} for User ${userId}. Ref: ${data.reference}`);

      // Initialize Supabase Admin client with service role key to bypass RLS
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

      if (!supabaseUrl || !supabaseServiceKey) {
        console.error('Supabase admin environment variables are missing');
        return NextResponse.json({ error: 'Supabase config missing' }, { status: 500 });
      }

      const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

      // Fetch user profile to get current credits
      const { data: profile, error: fetchError } = await supabaseAdmin
        .from('profiles')
        .select('credits')
        .eq('id', userId)
        .single();

      if (fetchError && fetchError.code !== 'PGRST116') { // PGRST116: no rows returned
        console.error('Error fetching user profile:', fetchError);
        return NextResponse.json({ error: 'Profile fetch failed' }, { status: 500 });
      }

      const currentCredits = profile?.credits || 0;
      const creditsToAdd = Number(credits) || 0;
      const newCredits = currentCredits + creditsToAdd;

      // Update user's profile with credits and membership tier
      const updatePayload: Record<string, any> = {
        credits: newCredits,
        updated_at: new Date().toISOString(),
      };

      if (tier && tier !== 'free') {
        updatePayload.membership_tier = tier;
      }

      const { error: updateError } = await supabaseAdmin
        .from('profiles')
        .update(updatePayload)
        .eq('id', userId);

      if (updateError) {
        console.error('Error updating user profile:', updateError);
        return NextResponse.json({ error: 'Profile update failed' }, { status: 500 });
      }

      console.log(`Successfully credited User ${userId} with ${creditsToAdd} credits. New total: ${newCredits}. Tier: ${tier || 'no-change'}`);
    }

    return NextResponse.json({ status: 'success' }, { status: 200 });
  } catch (error: any) {
    console.error('Paystack Webhook Error:', error);
    return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
  }
}
