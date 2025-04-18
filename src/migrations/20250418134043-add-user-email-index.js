'use strict';

const TABLE_NAME = 'users';
const INDEX_NAME = 'users_email_index';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addIndex(TABLE_NAME, ['email'], {
      unique: true,
      name: INDEX_NAME,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex(TABLE_NAME, INDEX_NAME);
  }
};

