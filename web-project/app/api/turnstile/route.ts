export async function POST(request: Request) {
  try {
    const { token, remoteip } = await request.json()

    if (!process.env.TURNSTILE_SECRET) {
      return new Response(JSON.stringify({ ok: false, error: 'Server not configured' }), {
        status: 500,
        headers: { 'content-type': 'application/json' }
      })
    }

    if (typeof token !== 'string' || token.length === 0) {
      return new Response(JSON.stringify({ ok: false, error: 'Missing token' }), {
        status: 400,
        headers: { 'content-type': 'application/json' }
      })
    }

    const form = new FormData()
    form.append('secret', process.env.TURNSTILE_SECRET)
    form.append('response', token)

    if (remoteip && typeof remoteip === 'string') {
      form.append('remoteip', remoteip)
    }

    const verifyResponse = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      body: form
    })

    if (!verifyResponse.ok) {
      return new Response(JSON.stringify({ ok: false, error: 'Verification failed' }), {
        status: 502,
        headers: { 'content-type': 'application/json' }
      })
    }

    const data = (await verifyResponse.json()) as { success?: boolean }
    const ok = Boolean(data.success)

    return new Response(JSON.stringify({ ok }), {
      status: ok ? 200 : 400,
      headers: { 'content-type': 'application/json' }
    })
  } catch (error) {
    console.error('Turnstile verification error', error)
    return new Response(JSON.stringify({ ok: false, error: 'Unexpected verification error' }), {
      status: 500,
      headers: { 'content-type': 'application/json' }
    })
  }
}
