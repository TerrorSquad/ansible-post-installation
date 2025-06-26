// https://github.com/nuxt-themes/docus/blob/main/nuxt.schema.ts
export default defineAppConfig({

  docus: {

    title: 'Griffin',
    description: 'Automate your post-installation tasks with Ansible',

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
      fluid: false
    },

    header: {
      logo: false,
      showLinkIcon: true,
      exclude: [],
      fluid: false
    },

    titleTemplate: '%s · Griffin',

    socials: {
      github: 'terrorsquad/ansible-post-installation',
    },

    layout: 'default',

    footer: {
      credits: {
        icon: '🚀',
        text: 'By Goran Ninkovic ' + (new Date()).getFullYear(),
        href: 'https://goranninkovic.com'
      },
      fluid: false
    },
  }
})
