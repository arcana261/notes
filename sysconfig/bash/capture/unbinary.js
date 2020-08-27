///BEGIN: unbinary
// buffer is Uint8Array
function unbinary(buffer, buffer_length) {
  let index = 0;
  let result = '';
  let fc_rgb = false;
  let bc_rgb = false;

  const read_int = function() {
    if (index >= buffer_length) {
      throw "expected an integer";
    }

    let result = buffer[index++];
    if (result <= 0x7F) {
      return result;
    }

    return (result & 0x7F) | (read_int() << 7);
  };

  const parse_flag = function() {
    let b = read_int();

    if (b & 0x1) {
      result += ' reset';
    }
    if (b & 0x2) {
      result += ' bg-reset';
    }
    if (b & 0x4) {
      result += ' bold';
    }
    if (b & 0x8) {
      result += ' italic';
    }
    if (b & 0x10) {
      fc_rgb = true;
    }
    if (b & 0x20) {
      bc_rgb = true;
    }
    if (b & 0x40) {
      result += ' highlighted';
    }
    if (b & 0x80) {
      result += ' underline';
    }
    if (b & 0x100) {
      result += ' crossed-out';
    }
    if (b & 0x200) {
      result += ' blink';
    }
  };

  const parse_rgb = function() {
    let value = read_int();

    let r = value & 0x0000FF;
    let encoded_g = (value >> 8) & 0x0000FF;
    let encoded_b = (value >> 16) & 0x0000FF;
    let g = encoded_g ^ r;
    let b = encoded_b ^ g;

    result += 'rgb(' + r + ',' + g + ',' + b + ')';
  };

  const parse_rgb_fc = function() {
    result += 'color:';
    parse_rgb();
  };

  const parse_rgb_bc = function() {
    result += 'background-color:';
    parse_rgb();
  };

  const parse_color = function() {
    if (!fc_rgb || !bc_rgb) {
      if (index >= buffer_length) {
        throw "expected a byte";
      }

      let b = buffer[index++];

      if (b & 0x20) {
        result += ' inverted';
      }
      if (b & 0x40) {
        result += ' bg-inverted';
      }

      //const fc = b & 0x07;
      //const bc = b & 0x38;

      // fc
      switch (b & 0x07) {
        case 0:
          result += ' white';
          break;
        case 1:
          result += ' red';
          break;
        case 2:
          result += ' green';
          break;
        case 3:
          result += ' yellow';
          break;
        case 4:
          result += ' blue';
          break;
        case 5:
          result += ' purple';
          break;
        case 6:
          result += ' cyan';
          break;
        case 7:
          result += ' dimgray';
          break;
        default:
          throw "unexpected foreground color";
      }

      // bc
      switch (b & 0x38) {
        case 0x00:
          result += ' bg-black';
          break;
        case 0x08:
          result += ' bg-red';
          break;
        case 0x10:
          result += ' bg-green';
          break;
        case 0x18:
          result += ' bg-yellow';
          break;
        case 0x20:
          result += ' bg-blue';
          break;
        case 0x28:
          result += ' bg-purple';
          break;
        case 0x30:
          result += ' bg-cyan';
          break;
        case 0x38:
          result += ' bg-white';
          break;
        default:
          throw "unexpected background color(" + (b & 0x38) + ") at offset " + index;
      }
    }

    if (fc_rgb || bc_rgb) {
      result += '" style="';
      if (fc_rgb) {
        parse_rgb_fc();
      }
      if (bc_rgb) {
        if (fc_rgb) {
          result += ';';
        }
        parse_rgb_bc();
      }
    }

    result += '"';
  };

  const copy_data = function(length) {
    if (index + length > buffer_length) {
      throw "unexpected end of buffer";
    }
    let section = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      section[i] = buffer[index + i];
    }
    index += length;

    result += new TextDecoder("utf-8").decode(section);
  };

  const parse_data = function() {
    length = read_int();
    copy_data(length);
  };

  const parse_span = function() {
    fc_rgb = bc_rgb = false;

    result += '<span class="';
    parse_flag();
    parse_color();
    result += '>';
    parse_data();
    result += '</span>';
  };

  while (index < buffer_length) {
    parse_span();
  }

  return result;
}
///END: unbinary

const fs = require("fs");

buffer = fs.readFileSync(process.argv[2], null)

console.log(unbinary(buffer, buffer.length));
