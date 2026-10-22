package com.peoplehub.department;

import java.util.ArrayList;
import java.util.List;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DepartmentService {

    private final DepartmentRepository repository;

    public DepartmentService(DepartmentRepository repository) {
        this.repository = repository;
    }

    /**
     * Departments almost never change, so the list is cached in Redis (cache name "departments",
     * TTL from application.yml). The first call hits PostgreSQL, later calls are served from Redis.
     */
    @Cacheable("departments")
    @Transactional(readOnly = true)
    public List<DepartmentDto> findAll() {
        List<DepartmentDto> result = new ArrayList<>();
        for (Department d : repository.findAllByOrderByNameAsc()) {
            result.add(new DepartmentDto(d.getId(), d.getCode(), d.getName()));
        }
        return result;
    }
}
