import axios from 'axios'

// All calls go to /api. In dev, Vite proxies this to http://localhost:8080 (see vite.config.ts).
// Day 2 adds an interceptor here that attaches the JWT to every request.
export const api = axios.create({
  baseURL: '/api',
  timeout: 15000,
})
