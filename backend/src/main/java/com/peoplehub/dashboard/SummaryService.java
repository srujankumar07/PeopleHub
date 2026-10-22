package com.peoplehub.dashboard;

import com.peoplehub.dashboard.SummaryDto.DepartmentHeadcount;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Aggregate queries use plain SQL through JdbcTemplate: for counts and group-bys this is simpler
 * and faster than loading entities. (Day 5 adds Redis caching here.)
 */
@Service
public class SummaryService {

    private static final String HEADCOUNT_BY_DEPARTMENT = """
            SELECT d.id, d.name, count(e.id) AS headcount
            FROM department d
            LEFT JOIN employee e ON e.department_id = d.id AND e.status <> 'INACTIVE'
            GROUP BY d.id, d.name
            ORDER BY d.name
            """;

    private final JdbcTemplate jdbc;

    public SummaryService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public SummaryDto getSummary() {
        List<DepartmentHeadcount> headcount = jdbc.query(
                HEADCOUNT_BY_DEPARTMENT,
                (rs, rowNum) -> new DepartmentHeadcount(rs.getLong("id"), rs.getString("name"), rs.getLong("headcount")));

        return new SummaryDto(
                count("SELECT count(*) FROM employee"),
                count("SELECT count(*) FROM employee WHERE status = 'ACTIVE'"),
                count("SELECT count(*) FROM department"),
                count("SELECT count(*) FROM hr_case WHERE status IN ('OPEN', 'IN_PROGRESS')"),
                count("SELECT count(*) FROM leave_request WHERE status = 'PENDING'"),
                headcount);
    }

    private long count(String sql) {
        Long value = jdbc.queryForObject(sql, Long.class);
        return value == null ? 0L : value;
    }
}
