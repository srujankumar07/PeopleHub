import Alert from '@mui/material/Alert'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import CircularProgress from '@mui/material/CircularProgress'
import LinearProgress from '@mui/material/LinearProgress'
import Paper from '@mui/material/Paper'
import Typography from '@mui/material/Typography'
import { useQuery } from '@tanstack/react-query'
import { fetchSummary } from '../api/summary'

const formatNumber = (value: number) => value.toLocaleString('en-IN')

interface StatCardProps {
  label: string
  value: number
}

function StatCard({ label, value }: StatCardProps) {
  return (
    <Paper variant="outlined" sx={{ p: 2.5 }}>
      <Typography variant="body2" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="h4">{formatNumber(value)}</Typography>
    </Paper>
  )
}

export default function DashboardPage() {
  const { data, isPending, isError, refetch } = useQuery({
    queryKey: ['summary'],
    queryFn: fetchSummary,
  })

  if (isPending) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', mt: 8 }}>
        <CircularProgress />
      </Box>
    )
  }

  if (isError) {
    return (
      <Alert
        severity="error"
        action={
          <Button color="inherit" size="small" onClick={() => refetch()}>
            Retry
          </Button>
        }
      >
        Could not load the dashboard. Is the backend running on port 8080?
      </Alert>
    )
  }

  const maxHeadcount = Math.max(1, ...data.headcountByDepartment.map((d) => d.headcount))

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>

      <Box
        sx={{
          display: 'grid',
          gap: 2,
          mb: 3,
          gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', lg: 'repeat(4, 1fr)' },
        }}
      >
        <StatCard label="Employees" value={data.totalEmployees} />
        <StatCard label="Active employees" value={data.activeEmployees} />
        <StatCard label="Open HR cases" value={data.openCases} />
        <StatCard label="Pending leave requests" value={data.pendingLeaveRequests} />
      </Box>

      <Paper variant="outlined" sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Headcount by department
        </Typography>
        {data.headcountByDepartment.map((row) => (
          <Box key={row.departmentId} sx={{ mb: 1.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2">{row.department}</Typography>
              <Typography variant="body2" color="text.secondary">
                {formatNumber(row.headcount)}
              </Typography>
            </Box>
            <LinearProgress
              variant="determinate"
              value={(row.headcount / maxHeadcount) * 100}
              sx={{ height: 8, borderRadius: 4 }}
            />
          </Box>
        ))}
      </Paper>
    </Box>
  )
}
