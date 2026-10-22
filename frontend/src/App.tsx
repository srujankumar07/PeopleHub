import { Route, Routes } from 'react-router-dom'
import Layout from './components/Layout'
import ComingSoonPage from './pages/ComingSoonPage'
import DashboardPage from './pages/DashboardPage'

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<DashboardPage />} />
        <Route path="employees" element={<ComingSoonPage title="Employee directory" day={2} />} />
        <Route path="leave" element={<ComingSoonPage title="Leave" day={3} />} />
        <Route path="attendance" element={<ComingSoonPage title="Attendance" day={4} />} />
        <Route path="cases" element={<ComingSoonPage title="HR cases" day={4} />} />
        <Route path="import" element={<ComingSoonPage title="Bulk import" day={5} />} />
        <Route path="*" element={<ComingSoonPage title="Page not found" />} />
      </Route>
    </Routes>
  )
}
