const cp = require("child_process");

function fixtures(element, userInput) {
  // ruleid: js-eval
  eval(userInput);
  // ruleid: js-innerhtml-dynamic
  element.innerHTML = userInput;
  // ok: js-innerhtml-dynamic
  element.innerHTML = "<b>static</b>";
  // ruleid: js-tls-verification-disabled
  const options = { host: "example.invalid", rejectUnauthorized: false };
  // ruleid: js-child-process-string-command
  cp.exec(`ls ${userInput}`);
  // ok: js-child-process-string-command
  cp.execFile("ls", [userInput]);
  return options;
}

module.exports = { fixtures };
