import { api } from './client'

export interface DepartmentHeadcount {
  departmentId: number
  department: string
  headcount: number
}

export interface Summary {
  totalEmployees: number
  activeEmployees: number
  departments: number
  openCases: number
  pendingLeaveRequests: number
  headcountByDepartment: DepartmentHeadcount[]
}

export const fetchSummary = () => api.get<Summary>('/summary').then((response) => response.data)
