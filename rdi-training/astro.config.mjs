// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightImageZoom from 'starlight-image-zoom'

import node from '@astrojs/node';

// https://astro.build/config
export default defineConfig({
  trailingSlash: 'always',
  integrations: [
    starlight({
      plugins: [
        starlightImageZoom(),
      ],
      components: {
        Sidebar: './src/components/CustomSidebar.astro',
      },
      pagefind:false,
      title: 'Redis Data Integration (RDI) Training',
      // social: {
      //     github: 'https://github.com/redis/redis',
      //     youtube: 'https://www.youtube.com/@Redisinc',
      // },
      customCss: [
        // Relative path to your custom CSS file
        './src/styles/custom.css',
      ],
      sidebar: [
        { label: 'Home', link: '/' },
        {
          label: 'Introduction',
          items: [
            'intro/welcome',
            'intro/intro-rdi',
            // 'intro/lab'
          ]
        },
        {
          label: 'Architecture',
          items: [
            'architecture/arch-overview',
            'architecture/ha-vm',
            'architecture/rdi-k8s'
          ]
        },
        {
          label: 'Database prep',
          items: [
            'prepare-databases/intro',
            'prepare-databases/prepare-redis',
            'prepare-databases/prepare-postgres'
          ]
        },
        {
          label: 'Install RDI',
          items: [
            'install-rdi/lab'
          ]
        },
        {
          label: 'Data pipelines',
          items: [
            'data-pipe/overview',
            'data-pipe/configuration-file',
            'data-pipe/job-file',
            'data-pipe/transf-denorm',
            'data-pipe/transf-examples',
            'data-pipe/lab',
            'data-pipe/challenges'
          ],
        },
        {
          label: 'Observability & troubleshooting',
          items: [
            'monitoring/overview',
            'monitoring/lab',
            'monitoring/troubleshoot',
          ]
        },
        // { label: 'Troubleshooting', link: '/troubleshooting/' },
        { label: 'Wrap up',
          items:[
            'wrap-up/key-takeaways',
            'wrap-up/key-term-cheatsheet',
            'wrap-up/finish-lab'
          ]
         }
      ],
    }),
  ],

  output: 'hybrid',

  adapter: node({
    mode: 'standalone',
  }),
  vite: {
    server: {
            allowedHosts: true,
    }
  }
});
