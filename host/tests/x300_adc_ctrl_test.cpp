#include "../lib/usrp/x300/x300_adc_ctrl.hpp"
#include <boost/make_shared.hpp>
#include <boost/test/unit_test.hpp>
#include <map>
#include <utility>

namespace {

/** \brief Record the last value written to each ADC register. */
class recording_spi : public uhd::spi_iface
{
public:
    /**
     * \brief Record an ADC register write.
     * \param which_slave the SPI slave device number
     * \param config the SPI configuration
     * \param data the encoded register transaction
     * \param num_bits the transaction width
     * \param readback whether the transaction reads a register
     * \return zero for a write
     */
    boost::uint32_t transact_spi(int which_slave,
        const uhd::spi_config_t &config, boost::uint32_t data,
        size_t num_bits, bool readback) override
    {
        BOOST_CHECK_EQUAL(which_slave, 0);
        BOOST_CHECK_EQUAL(num_bits, 16);
        BOOST_CHECK_EQUAL(config.mosi_edge, uhd::spi_config_t::EDGE_FALL);
        BOOST_REQUIRE(!readback);
        registers[(data >> 8) & 0xff] = data & 0xff;
        return 0;
    }

    /**
     * \brief Get the last value written to a register.
     * \param addr the ADC register address
     * \return the recorded register value
     */
    unsigned value(unsigned addr) const
    {
        return registers.at(addr);
    }

private:
    /** \brief Register addresses and their last written values. */
    std::map<unsigned, unsigned> registers{};
};

} // namespace

BOOST_AUTO_TEST_CASE(test_x300_adc_gain_preserves_half_db_steps)
{
    const auto spi = boost::make_shared<recording_spi>();
    const auto adc = x300_adc_ctrl::make(spi, 0);
    for (unsigned step = 0; step <= 12; ++step) {
        const double gain = 0.5 * step;
        BOOST_CHECK_EQUAL(adc->set_gain(gain), gain);
        BOOST_CHECK_EQUAL(spi->value(0x55) >> 4, step);
        BOOST_CHECK_EQUAL(spi->value(0x68) >> 4, step);
    }

    BOOST_CHECK_EQUAL(adc->set_gain(-1.0), 0.0);
    BOOST_CHECK_EQUAL(spi->value(0x55) >> 4, 0);
    BOOST_CHECK_EQUAL(spi->value(0x68) >> 4, 0);
    BOOST_CHECK_EQUAL(adc->set_gain(7.0), 6.0);
    BOOST_CHECK_EQUAL(spi->value(0x55) >> 4, 12);
    BOOST_CHECK_EQUAL(spi->value(0x68) >> 4, 12);
}

BOOST_AUTO_TEST_CASE(test_x300_adc_patterns_are_independent)
{
    const auto spi = boost::make_shared<recording_spi>();
    const auto adc = x300_adc_ctrl::make(spi, 0);
    const std::pair<const char *, unsigned> patterns[] = {
        {"normal", 0}, {"zeros", 1}, {"ones", 2}, {"ramp", 4}, {"custom", 5}
    };
    for (const auto &a : patterns) {
        for (const auto &b : patterns) {
            BOOST_TEST_CONTEXT("A=" << a.first << ", B=" << b.first) {
                adc->set_test_word(a.first, b.first, 0x2a35);
                BOOST_CHECK_EQUAL(spi->value(0x62) & 7, a.second);
                BOOST_CHECK_EQUAL(spi->value(0x75) & 7, b.second);
                BOOST_CHECK_EQUAL(spi->value(0x51), 0x35);
                BOOST_CHECK_EQUAL(spi->value(0x52), 0x2a);
            }
        }
    }
}
