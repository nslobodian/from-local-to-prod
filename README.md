<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Docker Compose Setup

This project includes a Docker Compose configuration for running the PostgreSQL database. Here's how to use it:

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- [Docker Compose](https://docs.docker.com/compose/install/) installed on your system

### Running the Database

1. Start the PostgreSQL container:
   ```bash
   docker-compose up -d
   ```

2. Check if the container is running:
   ```bash
   docker-compose ps
   ```

3. To stop the container:
   ```bash
   docker-compose down
   ```

4. To stop and remove all data (including the database volume):
   ```bash
   docker-compose down -v
   ```

### Configuration

The Docker Compose file (`docker-compose.yml`) includes the following configuration:

- PostgreSQL 16 (Alpine version)
- Port mapping: 5432 (host) -> 5432 (container)
- Default credentials:
  - Username: postgres
  - Password: postgres
  - Database: nestjs_sequelize
- Persistent volume for database data
- Health check configuration

### Environment Variables

Make sure your `.env` file matches the Docker Compose configuration:

```env
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=nestjs_sequelize
DB_HOST=localhost
DB_PORT=5432
```

### Troubleshooting

If you encounter issues:

1. Check if the container is running:
   ```bash
   docker-compose ps
   ```

2. View container logs:
   ```bash
   docker-compose logs postgres
   ```

3. Check database connectivity:
   ```bash
   docker-compose exec postgres psql -U postgres -d nestjs_sequelize
   ```

## Database Migrations

This project uses Sequelize migrations to manage database schema changes. Here's how to work with migrations:

### Prerequisites

Make sure your `.env` file contains the following database configuration:

```env
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=your_database_name
DB_HOST=localhost
DB_PORT=5432
```

### Available Commands

```bash
# Generate a new migration
$ npm run migration:generate your-migration-name

# Run all pending migrations
$ npm run migration:run

# Revert the last migration
$ npm run migration:revert

# Revert all migrations
$ npm run migration:revert:all
```

### Creating a New Migration

1. Generate a migration file:
   ```bash
   $ npm run migration:generate add-users-table
   ```

2. Edit the generated file in `src/migrations/` to define your schema changes:
   ```javascript
   module.exports = {
     up: async (queryInterface, Sequelize) => {
       await queryInterface.createTable('Users', {
         id: {
           allowNull: false,
           autoIncrement: true,
           primaryKey: true,
           type: Sequelize.INTEGER
         },
         name: {
           type: Sequelize.STRING,
           allowNull: false
         },
         email: {
           type: Sequelize.STRING,
           allowNull: false,
           unique: true
         },
         password: {
           type: Sequelize.STRING,
           allowNull: false
         },
         isActive: {
           type: Sequelize.BOOLEAN,
           defaultValue: true
         },
         createdAt: {
           allowNull: false,
           type: Sequelize.DATE
         },
         updatedAt: {
           allowNull: false,
           type: Sequelize.DATE
         }
       });
     },

     down: async (queryInterface, Sequelize) => {
       await queryInterface.dropTable('Users');
     }
   };
   ```

3. Run the migration:
   ```bash
   $ npm run migration:run
   ```

### Migration Best Practices

1. Always include a `down` method to revert changes
2. Use meaningful migration names that describe the change
3. Test migrations in a development environment before running in production
4. Keep migrations small and focused on a single change
5. Never modify a migration that has already been run in production

### Troubleshooting

If you encounter issues with migrations:

1. Check your database connection settings in `.env`
2. Ensure the database exists and is accessible
3. Verify that previous migrations have been run successfully
4. Check the Sequelize logs for detailed error messages

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
