package com.peoplehub.department;

import java.io.Serializable;

/** API shape for a department. Serializable because it is stored in the Redis cache. */
public record DepartmentDto(Long id, String code, String name) implements Serializable {
}
