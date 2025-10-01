/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: { bodySizeLimit: '1mb' },
  },
  output: 'standalone',
}

module.exports = nextConfig
