package com.peoplehub.department;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DepartmentRepository extends JpaRepository<Department, Long> {

    // Spring Data derives the SQL from the method name: SELECT ... FROM department ORDER BY name ASC
    List<Department> findAllByOrderByNameAsc();
}
