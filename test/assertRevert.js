module.exports = async (promise) => {
    try{
        await promise;
        assert.fail("Expecter revert not received")
    } catch(error) {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, 'Expected "rever", got ',error )
    }
}
