import AccessTimeIcon from '@mui/icons-material/AccessTime'
import DashboardIcon from '@mui/icons-material/Dashboard'
import EventAvailableIcon from '@mui/icons-material/EventAvailable'
import PeopleIcon from '@mui/icons-material/People'
import SupportAgentIcon from '@mui/icons-material/SupportAgent'
import UploadFileIcon from '@mui/icons-material/UploadFile'
import AppBar from '@mui/material/AppBar'
import Box from '@mui/material/Box'
import Drawer from '@mui/material/Drawer'
import List from '@mui/material/List'
import ListItemButton from '@mui/material/ListItemButton'
import ListItemIcon from '@mui/material/ListItemIcon'
import ListItemText from '@mui/material/ListItemText'
import Toolbar from '@mui/material/Toolbar'
import Typography from '@mui/material/Typography'
import type { ReactNode } from 'react'
import { Link, Outlet, useLocation } from 'react-router-dom'

const DRAWER_WIDTH = 240

interface NavItem {
  label: string
  to: string
  icon: ReactNode
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Dashboard', to: '/', icon: <DashboardIcon /> },
  { label: 'Employees', to: '/employees', icon: <PeopleIcon /> },
  { label: 'Leave', to: '/leave', icon: <EventAvailableIcon /> },
  { label: 'Attendance', to: '/attendance', icon: <AccessTimeIcon /> },
  { label: 'HR cases', to: '/cases', icon: <SupportAgentIcon /> },
  { label: 'Bulk import', to: '/import', icon: <UploadFileIcon /> },
]

export default function Layout() {
  const { pathname } = useLocation()

  const isSelected = (to: string) => (to === '/' ? pathname === '/' : pathname.startsWith(to))

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" noWrap component="div">
            PeopleHub
          </Typography>
        </Toolbar>
      </AppBar>

      <Drawer
        variant="permanent"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          '& .MuiDrawer-paper': { width: DRAWER_WIDTH, boxSizing: 'border-box' },
        }}
      >
        <Toolbar />
        <List sx={{ px: 1 }}>
          {NAV_ITEMS.map((item) => (
            <ListItemButton
              key={item.to}
              component={Link}
              to={item.to}
              selected={isSelected(item.to)}
              sx={{ borderRadius: 2, mb: 0.5 }}
            >
              <ListItemIcon sx={{ minWidth: 40 }}>{item.icon}</ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          ))}
        </List>
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, p: 3, minWidth: 0 }}>
        <Toolbar />
        <Outlet />
      </Box>
    </Box>
  )
}
