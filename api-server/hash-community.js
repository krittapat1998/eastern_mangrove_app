const bcrypt = require('bcrypt');

bcrypt.hash('community123!', 12).then(hash => {
  console.log('New hash for community123!:');
  console.log(hash);
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});