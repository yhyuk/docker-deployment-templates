/** @type {import('next').NextConfig} */
const nextConfig = {
  // Standalone 모드 활성화 (Docker 최적화)
  output: 'standalone',

  // 환경변수 설정
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  },

  // 이미지 최적화 설정
  images: {
    domains: ['localhost', 'your-domain.com'],
    // unoptimized: true, // 필요한 경우 이미지 최적화 비활성화
  },

  // 압축 설정
  compress: true,

  // 개발 환경 설정
  reactStrictMode: true,

  // 빌드 시 ESLint 에러 무시 (선택사항)
  // eslint: {
  //   ignoreDuringBuilds: true,
  // },

  // 빌드 시 TypeScript 에러 무시 (선택사항)
  // typescript: {
  //   ignoreBuildErrors: true,
  // },
}

module.exports = nextConfig
