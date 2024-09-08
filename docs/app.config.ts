// https://github.com/nuxt-themes/docus/blob/main/nuxt.schema.ts
export default defineAppConfig({
  docus: {
    title: 'Griffin',
    description: 'Automate your post-installation tasks with Ansible',
    // image: 'https://user-images.githubusercontent.com/904724/185365452-87b7ca7b-6030-4813-a2db-5e65c785bf88.png',
    // socials: {
    //   twitter: 'nuxt_js',
    //   github: 'nuxt-themes/docus',
    //   nuxt: {
    //     label: 'Nuxt',
    //     icon: 'simple-icons:nuxtdotjs',
    //     href: 'https://nuxt.com'
    //   }
    // },
    github: {
      dir: 'docs/content',
      branch: 'master',
      repo: 'ansible-post-installation',
      owner: 'terrorsquad',
      edit: true
    },
    aside: {
      level: 0,
      collapsed: false,
      exclude: []
    },
    main: {
      padded: true,
      fluid: true
    },
    header: {
      logo: false,
      showLinkIcon: true,
      exclude: [],
      fluid: true
    }
  }
})
