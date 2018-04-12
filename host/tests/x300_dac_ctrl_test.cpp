#include "../lib/usrp/x300/x300_dac_ctrl.hpp"
#include <boost/make_shared.hpp>
#include <boost/test/unit_test.hpp>
#include <stdexcept>
#include <utility>
#include <vector>

namespace {

/** \brief Record DAC writes and emulate successful PLL and FIFO locking. */
class recording_spi : public uhd::spi_iface
{
public:
    /**
     * \brief Record a write or return the requested DAC status register.
     * \param which_slave the SPI slave device number
     * \param config the SPI configuration
     * \param data the encoded register transaction
     * \param num_bits the transaction width
     * \param readback whether the transaction reads a register
     * \return the emulated register value, or zero for a write
     */
    boost::uint32_t transact_spi(int which_slave,
        const uhd::spi_config_t &config, boost::uint32_t data,
        size_t num_bits, bool readback) override
    {
        BOOST_CHECK_EQUAL(which_slave, 0);
        BOOST_CHECK_EQUAL(num_bits, 16);
        BOOST_CHECK_EQUAL(config.mosi_edge, uhd::spi_config_t::EDGE_RISE);
        const unsigned addr = (data >> 8) & 0x7f;
        if (!readback) {
            writes.emplace_back(addr, data & 0xff);
            return 0;
        }
        switch (addr) {
        case 0x06: return 0x50;
        case 0x0e: return 0x80;
        case 0x12: return 0x40;
        case 0x19: return 0x0f;
        default: throw std::runtime_error("Unexpected DAC register read");
        }
    }

    /**
     * \brief Get the values written to one register in transaction order.
     * \param addr the DAC register address
     * \return the recorded values for that register
     */
    std::vector<unsigned> values(unsigned addr) const
    {
        std::vector<unsigned> result;
        for (const auto &write : writes) {
            if (write.first == addr)
                result.push_back(write.second);
        }
        return result;
    }

private:
    /** \brief Register addresses and values in transaction order. */
    std::vector<std::pair<unsigned, unsigned> > writes{};
};

} // namespace

BOOST_AUTO_TEST_CASE(test_x300_dac_default_fullscale_survives_reset)
{
    const auto spi = boost::make_shared<recording_spi>();
    const auto dac = x300_dac_ctrl::make(spi, 0, 200e6);
    dac->verify_sync();
    dac->reset();

    const std::vector<unsigned> expected{0x81, 0x01, 0x81, 0x01};
    for (const unsigned addr : {0x41, 0x45}) {
        const auto actual = spi->values(addr);
        BOOST_CHECK_EQUAL_COLLECTIONS(actual.begin(), actual.end(),
            expected.begin(), expected.end());
    }
}

BOOST_AUTO_TEST_CASE(test_x300_dac_colosseum_fullscale_survives_reset)
{
    const auto spi = boost::make_shared<recording_spi>();
    const auto dac = x300_dac_ctrl::make(spi, 0, 200e6, true);
    dac->verify_sync();
    dac->reset();

    const std::vector<unsigned> expected{0x80, 0x00, 0x80, 0x00};
    for (const unsigned addr : {0x41, 0x45}) {
        const auto actual = spi->values(addr);
        BOOST_CHECK_EQUAL_COLLECTIONS(actual.begin(), actual.end(),
            expected.begin(), expected.end());
    }
}
