"use strict";

import TextReader from "https://jsr.io/@ltgc/rochelle/0.2.8/dist/textRead.mjs";
import DsvParser from "https://jsr.io/@ltgc/rochelle/0.2.8/dist/dsvParse.mjs";

let lossySizes = new Map();
let lossySsimu = new Map();
let lossyLength = new Map();

let addToMap = (map, key, number) => {
	let value;
	if (map.has(key)) {
		value = map.get(key);
	} else {
		value = 0;
	};
	value += number;
	map.set(key, value);
	return value;
};

for await (let line of DsvParser.parseObjects(DsvParser.DATA_TEXT, TextReader.line((await Deno.open(`./data/${Deno.args[0]}.lossy.size.tsv`)).readable))) {
	if (line.testId) {
		addToMap(lossySizes, line.testId, parseInt(line.size));
	};
};
for await (let line of DsvParser.parseObjects(DsvParser.DATA_TEXT, TextReader.line((await Deno.open(`./data/${Deno.args[0]}.lossy.ssim.tsv`)).readable))) {
	if (line.testId && line.ssimu2 > 0) {
		//console.debug(parseFloat(line.ssimu2));
		addToMap(lossySsimu, line.testId, parseFloat(line.ssimu2));
		addToMap(lossyLength, line.testId, 1);
	};
};

for (let pair of lossySizes) {
	//console.debug(pair);
	if (pair[0] !== "source" && pair[0].indexOf(".ppm") !== -1) {
		lossySsimu.set(pair[0].substring(0, pair[0].length - 4), lossySsimu.get(pair[0]));
		lossyLength.set(pair[0].substring(0, pair[0].length - 4), lossyLength.get(pair[0]));
	};
};
for (let pair of lossySizes) {
	if (pair[0] !== "source" && pair[0].indexOf(".ppm") === -1) {
		console.debug(`${pair[0]}: ${Math.round(10000 * lossySizes.get(pair[0]) / lossySizes.get("source")) / 100}%, SSIMU2 ${Math.round(100 * lossySsimu.get(pair[0]) / lossyLength.get(pair[0])) / 100}`);
	};
};