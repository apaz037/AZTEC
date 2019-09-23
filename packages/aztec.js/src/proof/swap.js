/* eslint-disable func-names */
const helpers = require('./exportHandler/helpers');
const exportHandler = require('./exportHandler');
const ProofType = require('./base/types');

/**
 * Export the SwapProof for a default epoch
 *
 * @method SwapProof
 * @param  {...any} args - rest parameter representing the proof inputs
 * @returns A SwapProof construction for the default epoch
 */
function SwapProof(...args) {
    return exportHandler.exportProof.bind({ epochNum: this.epochNum })(ProofType.SWAP.name, ...args);
}

/**
 * Export the SwapProof for a given epoch number
 *
 * @method epoch
 * @param {Number} epochNum - epoch number for which a SwapProof is to be returned
 * @param {bool} setDefaultEpoch - if true, sets the inputted epochNum to be the default. If false, does
 * not set the inputted epoch number to be the default
 * @returns A SwapProof construction for the given epoch number
 */
SwapProof.epoch = function(epochNum, setDefaultEpoch = false) {
    helpers.validateEpochNum(epochNum);

    if (setDefaultEpoch) {
        exportHandler.setDefaultEpoch(ProofType.SWAP.name, epochNum);
    }

    return (...args) => {
        return SwapProof.bind({ epochNum })(...args);
    };
};

module.exports = SwapProof;
