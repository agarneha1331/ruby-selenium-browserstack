require 'rubygems'
require 'selenium-webdriver'

USER_NAME = ENV['BROWSERSTACK_USERNAME'] || "YOUR_USER_NAME"
ACCESS_KEY = ENV['BROWSERSTACK_ACCESS_KEY'] || "YOUR_ACCESS_KEY"

def run_session(capabililties)
    options = Selenium::WebDriver::Options.send capabililties['browserName']
    options.browser_version = capabililties['browserVersion'] if capabililties['browserVersion']
    capabililties['bstack:options']['source'] = 'ruby:sample-main:v1.0'
    options.add_option('bstack:options', capabililties['bstack:options'])

    driver = Selenium::WebDriver.for(
        :remote,
        :url => "https://#{USER_NAME}:#{ACCESS_KEY}@hub.browserstack.com/wd/hub",
        :capabilities => options
    )
    begin
        # opening the bstackdemo.com website
        driver.navigate.to "https://bstackdemo.com"
        wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
        wait.until { !driver.title.match(/StackDemo/i).nil? }

        # getting name of the product available on the webpage
        product = driver.find_element(:xpath, '//*[@id="1"]/p')
        wait.until { product.displayed? }
        product_text = product.text

        # wait until the Add to Cart button is displayed on webpage, then click it
        cart_btn = driver.find_element(:xpath, '//*[@id="1"]/div[4]')
        wait.until { cart_btn.displayed? }
        cart_btn.click

        # waiting until the Cart pane appears
        wait.until { 
            driver.find_element(
                :xpath, 
                '//*[@id="__next"]/div/div/div[2]/div[2]/div[2]/div/div[3]/p[1]'
            ).displayed? 
        }

        # get name of the product in the cart
        product_in_cart = driver.find_element(
            :xpath, 
            '//*[@id="__next"]/div/div/div[2]/div[2]/div[2]/div/div[3]/p[1]'
        )
        wait.until { product_in_cart.displayed? }
        product_in_cart_text = product_in_cart.text

        # check if the product has been added to the cart
        if product_text.eql? product_in_cart_text
            # mark test as 'passed' if the product is successfully added to the cart
            driver.execute_script(
                'browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"passed", "reason": "Product has been successfully added to the cart!"}}'
            )
        else
            # mark test as 'failed' if the product is not added to the cart
            driver.execute_script(
                'browserstack_executor: {"action": "setSessionStatus", "arguments": {"status":"failed", "reason": "Failed to add product to the cart"}}'
            )
        end
    rescue StandardError => e
        puts "Exception occured: #{e.message}"
        # mark test as 'failed' if test script is unable to open the bstackdemo.com website
        driver.execute_script(
            'browserstack_executor: {"action": "setSessionStatus", "arguments": {"status": "failed", "reason":' +  "\"#{e.message}\"" + ' }}'
        )
    ensure
        driver.quit
    end
end

capabililties = [
    {
        'bstack:options' => {
            'os': 'OS X',
            'osVersion' => 'Monterey',
            'buildName' => 'browserstack-build-1',
            'sessionName' => 'BStack parallel ruby'
        },
        'browserName' =>  'chrome',
        'browserVersion' => 'latest'
    },
    {
        'bstack:options' => {
            'os': 'Windows',
            'osVersion' => '11',
            'buildName' => 'browserstack-build-1',
            'sessionName' => 'BStack parallel ruby'
        },
        'browserName' =>  'firefox',
        'browserVersion' => 'latest'
    },
    {
        'bstack:options' => {
            'osVersion' => '10.0',
            'deviceName' => 'Samsung Galaxy S20',
            'buildName' => 'browserstack-build-1',
            'sessionName' => 'BStack parallel ruby'
        },
        'browserName' =>  'chrome'
    }
]

test1 = Thread.new { run_session(capabililties[0]) }
test2 = Thread.new { run_session(capabililties[1]) }
test3 = Thread.new { run_session(capabililties[2]) }

test1.join()
test2.join()
test3.join()
