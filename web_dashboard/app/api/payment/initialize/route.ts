import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { email, amount, reference, userId, credits, tier } = await request.json();

    if (!email || !amount || !reference || !userId) {
      return NextResponse.json(
        { error: 'Missing required parameters (email, amount, reference, userId)' },
        { status: 400 }
      );
    }

    const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
    if (!paystackSecret) {
      return NextResponse.json(
        { error: 'Server configuration error: PAYSTACK_SECRET_KEY is missing' },
        { status: 500 }
      );
    }

    // Call Paystack API securely using server-side environment variable
    const response = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${paystackSecret}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        amount: Math.round(amount * 100), // Convert to cents
        reference,
        metadata: {
          userId,
          credits,
          tier,
        },
      }),
    });

    const data = await response.json();

    if (!response.ok || !data.status) {
      return NextResponse.json(
        { error: data.message || 'Failed to initialize transaction with Paystack' },
        { status: response.status }
      );
    }

    return NextResponse.json({
      status: true,
      data: {
        authorization_url: data.data.authorization_url,
        reference: data.data.reference,
      },
    });
  } catch (error: any) {
    console.error('Initialize Transaction Error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal Server Error' },
      { status: 500 }
    );
  }
}
