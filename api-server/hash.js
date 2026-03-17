const bcrypt = require('bcrypt');

bcrypt.hash('admin123!', 12).then(hash => {
  console.log('New hash for admin123!:');
  console.log(hash);
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});