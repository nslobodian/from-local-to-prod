import { Dialect } from 'sequelize';

export const databaseConfig = {
  development: {
    username: 'postgres',
    password: 'postgres',
    database: 'nestjs_sequelize',
    host: 'localhost',
    port: 5432,
    dialect: 'postgres' as Dialect,
    logging: console.log,
  },
  test: {
    username: 'postgres',
    password: 'postgres',
    database: 'nestjs_sequelize_test',
    host: 'localhost',
    port: 5432,
    dialect: 'postgres' as Dialect,
    logging: false,
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    dialect: 'postgres' as Dialect,
    logging: false,
  },
};
