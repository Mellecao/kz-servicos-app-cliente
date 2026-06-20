import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SERVICE_ACCOUNT: ServiceAccount = JSON.parse(
  Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!
)

interface ServiceAccount {
  project_id: string
  private_key: string
  client_email: string
}

const statusMessages: Record<string, { title: string; body: string }> = {
  searching_drivers: {
    title: '🔍 Buscando motorista',
    body: 'Estamos buscando o motorista ideal para sua viagem.',
  },
  awaiting_client_confirmation: {
    title: '🚗 Motorista encontrado!',
    body: 'Um motorista aceitou sua viagem. Confirme para prosseguir.',
  },
  awaiting_driver_confirmation: {
    title: '⏳ Aguardando confirmação',
    body: 'Aguardando a confirmação final do motorista.',
  },
  scheduled: {
    title: '✅ Viagem confirmada',
    body: 'Sua viagem foi confirmada com o motorista.',
  },
  started: {
    title: '🚀 Viagem iniciada',
    body: 'Sua viagem começou. Boa viagem!',
  },
  completed: {
    title: '🏁 Viagem concluída',
    body: 'Sua viagem foi concluída. Obrigado por usar o KZ Serviços!',
  },
  cancelled: {
    title: '❌ Viagem cancelada',
    body: 'Sua viagem foi cancelada.',
  },
}

// ----- FCM V1 via Service Account (OAuth2) --------------------------------

function base64url(data: Uint8Array | string): string {
  const str = typeof data === 'string' ? data : String.fromCharCode(...data)
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const binary = atob(b64)
  const buf = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) buf[i] = binary.charCodeAt(i)
  return buf.buffer
}

async function getFcmAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64url(JSON.stringify({
    iss: SERVICE_ACCOUNT.client_email,
    sub: SERVICE_ACCOUNT.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))

  const signingInput = `${header}.${payload}`

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(SERVICE_ACCOUNT.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput),
  )

  const jwt = `${signingInput}.${base64url(new Uint8Array(sig))}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const { access_token } = await res.json()
  return access_token
}

// --------------------------------------------------------------------------

serve(async (req) => {
  try {
    const { trip_id, client_id, new_status } = await req.json()

    const notification = statusMessages[new_status]
    if (!notification) {
      return new Response('Status sem notificação configurada', { status: 200 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    const { data: user, error } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', client_id)
      .single()

    if (error || !user?.fcm_token) {
      console.log(`Sem token FCM para cliente ${client_id}`)
      return new Response('Token não encontrado', { status: 200 })
    }

    const accessToken = await getFcmAccessToken()

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${SERVICE_ACCOUNT.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: user.fcm_token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            android: {
              notification: {
                channel_id: 'kz_trip_channel',
                priority: 'HIGH',
              },
            },
            apns: {
              payload: { aps: { badge: 1, sound: 'default' } },
            },
            data: { trip_id, status: new_status },
          },
        }),
      },
    )

    const result = await fcmRes.json()
    console.log(`FCM V1 enviado para trip ${trip_id}:`, result)

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Erro na Edge Function:', err)
    return new Response(String(err), { status: 500 })
  }
})
