package com.peoplehub.dashboard;

import java.io.Serializable;
import java.util.List;

/** Numbers shown on the dashboard home page. */
public record SummaryDto(
        long totalEmployees,
        long activeEmployees,
        long departments,
        long openCases,
        long pendingLeaveRequests,
        List<DepartmentHeadcount> headcountByDepartment) implements Serializable {

    public record DepartmentHeadcount(Long departmentId, String department, long headcount) implements Serializable {
    }
}
