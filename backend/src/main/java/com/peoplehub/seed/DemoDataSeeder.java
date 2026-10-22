package com.peoplehub.seed;

import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.support.EncodedResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.springframework.stereotype.Component;

/**
 * Loads demo data (100k employees and related rows) on startup, only when the "seed" profile is active
 * and the employee table is empty. The whole script runs in one transaction: it either all loads or
 * nothing does.
 */
@Component
@ConditionalOnProperty(name = "peoplehub.seed.enabled", havingValue = "true")
public class DemoDataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoDataSeeder.class);
    private static final String SCRIPT = "db/seed/demo-data.sql";

    private final DataSource dataSource;
    private final JdbcTemplate jdbc;

    public DemoDataSeeder(DataSource dataSource, JdbcTemplate jdbc) {
        this.dataSource = dataSource;
        this.jdbc = jdbc;
    }

    @Override
    public void run(String... args) throws Exception {
        Long existing = jdbc.queryForObject("SELECT count(*) FROM employee", Long.class);
        if (existing != null && existing > 0) {
            log.info("Seed skipped: {} employees already exist", existing);
            return;
        }

        log.info("Seeding demo data from {} ...", SCRIPT);
        long started = System.currentTimeMillis();

        try (Connection connection = dataSource.getConnection()) {
            connection.setAutoCommit(false);
            try {
                ScriptUtils.executeSqlScript(
                        connection, new EncodedResource(new ClassPathResource(SCRIPT), StandardCharsets.UTF_8));
                connection.commit();
            } catch (RuntimeException | Error e) {
                connection.rollback();
                throw e;
            }
        }

        log.info("Seed finished in {} ms", System.currentTimeMillis() - started);
    }
}
