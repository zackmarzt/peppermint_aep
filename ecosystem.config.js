module.exports = {
  apps: [
    {
      name: "client",
      script: "server.js", // Executa diretamente
      interpreter: "bun",  // Força o uso do Bun
      cwd: "apps/client",
      instances: "1",
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOSTNAME: "0.0.0.0" // Importante para Docker
      },
    },
    {
      name: "api",
      script: "dist/main.js",
      interpreter: "bun", // Força o uso do Bun
      cwd: "apps/api",
      instances: "1",
      autorestart: true,
      watch: false,
      restart_delay: 3000,
      env: {
        NODE_ENV: "production",
        DB_USERNAME: process.env.DB_USERNAME,
        DB_PASSWORD: process.env.DB_PASSWORD,
        DB_HOST: process.env.DB_HOST,
        secret: process.env.SECRET,
      },
    },
  ],
};