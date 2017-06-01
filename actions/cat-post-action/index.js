/**
 * Copyright 2017 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/**
 * This action adds a new cat to a MySQL database.
 *
 * @param   params.MYSQL_HOSTNAME    MySQL hostname
 * @param   params.MYSQL_USERNAME    MySQL username
 * @param   params.MYSQL_PASSWORD    MySQL password
 * @param   params.MYSQL_DATABASE    MySQL database
 * @param   params.name              Name of the cat to insert into the table
 * @param   params.color             Color of the cat to insert into the table

 * @return  Promise for the MySQL result
 */
function myAction(params) {

  var returnValue = {};

  console.log('Setting up MySQL database');
  var mysql = require('mysql');
  var connection = mysql.createConnection({
    host: params.MYSQL_HOSTNAME,
    user: params.MYSQL_USERNAME,
    password: params.MYSQL_PASSWORD,
    database: params.MYSQL_DATABASE
  });

  console.log('Connecting');
  connection.connect(function(err) {
    if (err) {
      console.error('Error connecting: ' + err.stack);
      return {
        headers: {
          'Content-Type': 'application/json'
        },
        statusCode: 500,
        body: '{ error: "Connection error." }'
      };
    }
  });

  console.log('Querying');

  connection.query('CREATE TABLE IF NOT EXISTS `cats` (`id` INT AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(256) NOT NULL, `color` VARCHAR(256) NOT NULL)', function(err, result) {
    if (err) {
      console.log("Error creating the cats table...");
      returnValue = {
        headers: {
          'Content-Type': 'application/json'
        },
        statusCode: 500,
        body: '{ error: "SQL error." }'
      };
    }

    var queryText = 'INSERT INTO cats (name, color) VALUES(?, ?)';

    connection.query(queryText, [params.name, params.color], function(error, result) {
      if (error) {
        console.log(error);
        returnValue = {
          headers: {
            'Content-Type': 'application/json'
          },
          statusCode: 500,
          body: '{ error: "SQL error." }'
        };
      } else {
        returnValue = {
          statusCode: 201,
          headers: {
            'Content-Type': 'application/json'
          },
          body: '{ success: "' + result.insertId + '" }'
        };
      }
      console.log('Disconnecting from the MySQL database.');
      connection.end(function(err) {
        console.log("Error on connection end: " + err.stack);
      });
    });

  });

  return returnValue;

}

exports.main = myAction;
