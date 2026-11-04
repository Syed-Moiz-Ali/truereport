package db.migration;

import com.truereport.shared.security.PiiCrypto;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.UUID;

/**
 * One-time data migration for existing fake/development PII. It is a no-op when
 * there are no rows, which keeps fresh H2 and Testcontainers databases simple.
 * A production run requires APP_PII_KEYS or APP_ENCRYPTION_KEY.
 */
public class V16__Encrypt_existing_pii extends BaseJavaMigration {

    private static final String JOB_TRIGGER = "trg_inspection_jobs_no_update_after_finalize";
    private static final String SNAPSHOT_TRIGGER = "trg_final_snapshots_no_update";

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        boolean jobs = hasRows(connection, "inspection_jobs");
        boolean snapshots = hasRows(connection, "inspection_final_snapshots");
        if (!jobs && !snapshots) {
            return;
        }
        PiiCrypto crypto = PiiCrypto.fromEnvironment();
        if (crypto == null) {
            throw new IllegalStateException(
                    "APP_PII_KEYS or APP_ENCRYPTION_KEY is required to encrypt existing PII");
        }
        boolean mysql = connection.getMetaData().getDatabaseProductName()
                .toLowerCase().contains("mysql");
        if (jobs) {
            if (mysql) {
                dropTrigger(connection, JOB_TRIGGER);
            }
            try {
                encryptJobs(connection, crypto);
            } finally {
                if (mysql) {
                    createJobTrigger(connection);
                }
            }
        }
        if (snapshots) {
            if (mysql) {
                dropTrigger(connection, SNAPSHOT_TRIGGER);
            }
            try {
                encryptSnapshots(connection, crypto);
            } finally {
                if (mysql) {
                    createSnapshotTrigger(connection);
                }
            }
        }
    }

    private void encryptJobs(Connection connection, PiiCrypto crypto) throws Exception {
        String select = "SELECT id, customer_name, customer_phone, customer_email, "
                + "vehicle_vin, vehicle_plate FROM inspection_jobs";
        try (Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(select);
             PreparedStatement update = connection.prepareStatement(
                     "UPDATE inspection_jobs SET customer_name=?, customer_phone=?, customer_email=?, "
                             + "vehicle_vin=?, vehicle_plate=? WHERE id=?")) {
            while (rows.next()) {
                update.setString(1, encrypt(crypto, rows.getString("customer_name")));
                update.setString(2, encrypt(crypto, rows.getString("customer_phone")));
                update.setString(3, encrypt(crypto, rows.getString("customer_email")));
                update.setString(4, encrypt(crypto, rows.getString("vehicle_vin")));
                update.setString(5, encrypt(crypto, rows.getString("vehicle_plate")));
                update.setObject(6, rows.getObject("id"));
                update.addBatch();
            }
            update.executeBatch();
        }
    }

    private void encryptSnapshots(Connection connection, PiiCrypto crypto) throws Exception {
        String select = "SELECT id, snapshot_json FROM inspection_final_snapshots";
        try (Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(select);
             PreparedStatement update = connection.prepareStatement(
                     "UPDATE inspection_final_snapshots SET snapshot_json=? WHERE id=?")) {
            while (rows.next()) {
                update.setString(1, encrypt(crypto, rows.getString("snapshot_json")));
                update.setObject(2, rows.getObject("id"));
                update.addBatch();
            }
            update.executeBatch();
        }
    }

    private String encrypt(PiiCrypto crypto, String value) {
        if (value == null || value.isEmpty() || crypto.isEncrypted(value)) {
            return value;
        }
        return crypto.encrypt(value);
    }

    private boolean hasRows(Connection connection, String table) throws Exception {
        try (Statement statement = connection.createStatement();
             ResultSet result = statement.executeQuery("SELECT COUNT(*) FROM " + table)) {
            result.next();
            return result.getLong(1) > 0;
        }
    }

    private void dropTrigger(Connection connection, String trigger) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.execute("DROP TRIGGER IF EXISTS " + trigger);
        }
    }

    private void createJobTrigger(Connection connection) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.execute("""
                    CREATE TRIGGER trg_inspection_jobs_no_update_after_finalize
                    BEFORE UPDATE ON inspection_jobs
                    FOR EACH ROW
                    BEGIN
                        IF OLD.status = 'FINALIZED' THEN
                            SIGNAL SQLSTATE '45000'
                                SET MESSAGE_TEXT = 'Finalized inspections are immutable';
                        END IF;
                    END
                    """);
        }
    }

    private void createSnapshotTrigger(Connection connection) throws Exception {
        try (Statement statement = connection.createStatement()) {
            statement.execute("""
                    CREATE TRIGGER trg_final_snapshots_no_update
                    BEFORE UPDATE ON inspection_final_snapshots
                    FOR EACH ROW
                    BEGIN
                        SIGNAL SQLSTATE '45000'
                            SET MESSAGE_TEXT = 'Final inspection snapshots are immutable';
                    END
                    """);
        }
    }
}
