///BEGIN: undiff
// current, diff, result are Uint8Array
function undiff(current, current_length, diff, result) {
  let current_index = 0;
  let diff_index = 0;
  let result_index = 0;

  const KEEP_COMMAND = 'K'.charCodeAt(0);
  const INSERT_COMMAND = 'I'.charCodeAt(0);
  const DELETE_COMMAND = 'D'.charCodeAt(0);
  const REPLACE_COMMAND = 'R'.charCodeAt(0);

  const read_int = function() {
    if (diff_index >= diff.length) {
      throw "expected an integer";
    }

    let int_result = diff[diff_index++];
    if (int_result <= 0x7F) {
      return int_result;
    }

    return (int_result & 0x7F) | (read_int() << 7);
  };

  const ensure_result = function(length) {
    let more = result_index + length - result.length;
    if (more > 0) {
      let new_cap = 2 * result.length;
      if (more > result.length) {
        new_cap = result.length + more;
      }

      let new_result = new Uint8Array(new_cap);
      for (let i = 0; i < result_index; i++) {
        new_result[i] = result[i];
      }

      result = new_result;
    }
  };

  const copy_data = function(source, source_length, from, length) {
    if (from + length > source_length) {
      throw "unexpected end of buffer";
    }
    ensure_result(length);
    for (let i = 0; i < length; i++) {
      result[result_index + i] = source[from + i];
    }
    result_index += length;
  };

  while (diff_index < diff.length) {
    let cmd = diff[diff_index++];
    let size = 0;

    switch (cmd) {
      case KEEP_COMMAND:
        size = read_int();
        copy_data(current, current_length, current_index, size);
        current_index += size;
        break;

      case INSERT_COMMAND:
        size = read_int();
        copy_data(diff, diff.length, diff_index, size);
        diff_index += size;
        break;

      case DELETE_COMMAND:
        size = read_int();
        current_index += size;
        if (current_index > current_length) {
          throw "DELETE: current out of range, diff_index=" + diff_index + ",current_index=" + current_index + ",size=" + size + ",current_length=" + current_length;
        }
        break;

      case REPLACE_COMMAND:
        size = read_int();
        copy_data(diff, diff.length, diff_index, size);
        diff_index += size;
        current_index += size;
        if (current_index > current_length) {
          throw "REPLACE: current out of range, diff_index=" + diff_index + ",current_index=" + current_index + ",size=" + size + ",current_length=" + current_length;
        }
        break;

      default:
        throw "unknown command: " + cmd;
    }
  }

  return {
    'result': result,
    'length': result_index,
  };
}
///END: undiff

const fs = require("fs");

current = fs.readFileSync(process.argv[2], null)
diff = fs.readFileSync(process.argv[3], null)

let x = undiff(current, current.length, diff, new Uint8Array(0));

let result = x['result'];
let result_length = x['length'];

let target = new Uint8Array(result_length);
for (let i = 0; i < result_length; i++) {
  target[i] = result[i];
}

console.log(result_length);

fs.writeFileSync(process.argv[4], target, 'binary')
