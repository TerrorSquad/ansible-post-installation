export default defineAppConfig({
  seo: {
    title: "Griffin",
    description: "Automate your post-installation tasks with Ansible",
    titleTemplate: "%s · Griffin",
  },

  header: {
    title: "Griffin",
    logo: {
      alt: "Griffin",
      light: "",
      dark: "",
    },
  },

  github: {
    owner: "terrorsquad",
    name: "ansible-post-installation",
    branch: "master",
    rootDir: "docs",
    url: "https://github.com/terrorsquad/ansible-post-installation",
  },

  socials: {
    github: "terrorsquad/ansible-post-installation",
    linkedin: {
      label: "LinkedIn",
      icon: "i-simple-icons-linkedin",
      href: "https://www.linkedin.com/in/goran-ninkovic/",
    },
  },

  ui: {
    colors: {
      primary: "emerald",
      neutral: "gray",
    },
  },
});
