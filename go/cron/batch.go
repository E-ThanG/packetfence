package maint

import (
	"context"
	"database/sql"
	"github.com/go-sql-driver/mysql"
	"github.com/inverse-inc/go-utils/log"
	"time"
)

func BatchStmt(ctx context.Context, time_limit time.Duration, stmt *sql.Stmt, args ...interface{}) (int64, error) {
	start := time.Now()
	rows_affected := int64(0)
	for {
		results, err := stmt.Exec(args...)
		if err != nil {
			log.LogError(ctx, "Database error: "+err.Error())
			return rows_affected, err
		}

		rows, err := results.RowsAffected()
		if err != nil {
			log.LogError(ctx, "Database error: "+err.Error())
			return rows_affected, err
		}

		if rows <= 0 {
			break
		}

		rows_affected += rows
		if time.Now().Sub(start) > time_limit {
			break
		}
	}

	return rows_affected, nil
}

func BatchStmtQueryWithCount(ctx context.Context, time_limit time.Duration, stmt *sql.Stmt, args ...interface{}) (int64, error) {
	start := time.Now()
	rows_affected := int64(0)
	var err error
	for {
		var count int64
		err = stmt.QueryRow(args...).Scan(&count)
		if err != nil {
			if merr, ok := err.(*mysql.MySQLError); ok {
				log.LogError(ctx, "Retrying query: "+merr.Error())
				time.Sleep(time.Millisecond * 10)
				continue
			}
			log.LogError(ctx, "Database error: "+err.Error())
			break
		}

		if count == 0 {
			break
		}

		if count < 0 {
			log.LogWarn(ctx, "Retrying statement query")
			time.Sleep(10 * time.Millisecond)
		} else {
			rows_affected += count
		}

		if time.Now().Sub(start) > time_limit {
			break
		}
	}

	return rows_affected, err
}

func BatchSql(ctx context.Context, timeout time.Duration, sql string, args ...interface{}) (int64, error) {
	db, err := getDb()
	if err != nil {
		log.LogError(ctx, err.Error())
		return -1, err
	}

	stmt, err := db.Prepare(sql)
	if err != nil {
		log.LogError(ctx, err.Error())
		return -1, err
	}

	defer stmt.Close()
	return BatchStmt(ctx, timeout, stmt, args...)
}

func BatchSqlCount(ctx context.Context, timeout time.Duration, sql string, args ...interface{}) (int64, error) {
	db, err := getDb()
	if err != nil {
		log.LogError(ctx, err.Error())
		return -1, err
	}

	stmt, err := db.Prepare(sql)
	if err != nil {
		log.LogError(ctx, err.Error())
		return -1, err
	}

	defer stmt.Close()
	return BatchStmtQueryWithCount(ctx, timeout, stmt, args...)
}
