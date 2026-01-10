export default defineNuxtConfig({
  // https://github.com/nuxt-themes/docus
  extends: ["docus"],

  devtools: { enabled: true },

  app: {
    baseURL: '/ansible-post-installation/',
    buildAssetsDir: 'assets',
  },

  site: {
    url: 'https://terrorsquad.github.io/ansible-post-installation',
    name: 'Griffin',
  },

  robots: {
    robotsTxt: false,
  },

  modules: [
    // Remove it if you don't use Plausible analytics
    // https://github.com/nuxt-modules/plausible
    "@nuxtjs/plausible",
  ],

  compatibilityDate: "2024-09-08",

  vite: {
    optimizeDeps: {
      include: [
        "@vue/devtools-core",
        "@vue/devtools-kit",
      ]
    }
  },
});
