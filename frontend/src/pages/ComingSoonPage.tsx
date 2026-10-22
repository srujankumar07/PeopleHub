import Paper from '@mui/material/Paper'
import Typography from '@mui/material/Typography'

interface Props {
  title: string
  day?: number
}

export default function ComingSoonPage({ title, day }: Props) {
  return (
    <Paper variant="outlined" sx={{ p: 4 }}>
      <Typography variant="h5" gutterBottom>
        {title}
      </Typography>
      <Typography color="text.secondary">
        {day ? `This screen is built on Day ${day} of the plan.` : 'There is nothing at this address.'}
      </Typography>
    </Paper>
  )
}
