<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<template>
  <div class="text-sm text-gray-500 dark:text-gray-400">
    <a
      href="https://goranninkovic.com"
      target="_blank"
      rel="noopener noreferrer"
      class="hover:underline flex items-center gap-1"
    >
      🚀 By Goran Ninkovic {{ year }}
    </a>
  </div>
</template>
