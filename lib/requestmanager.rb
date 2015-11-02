require 'selenium-webdriver'
require 'uri'
require 'pry'


class RequestManager
  def initialize(proxy_list, request_interval)
    @proxy_list = parse_proxy_list(proxy_list)
    @request_interval = request_interval
    @used_proxies = Hash.new
  end

  # Get the page requested
  def get_page(url, form_input = nil)
    chosen_proxy = @proxy_list != nil ? get_random_proxy(url) : nil
    driver = gen_driver(chosen_proxy)
    driver.navigate.to url
    puts "Getting page " + url

    # Handle form input if there is any
    if form_input
      element = driver.find_element(name: "q")
      element.send_keys form_input
      element.submit
    end
    
    page_html = driver.page_source
    driver.quit
    return page_html
  end
  
  # Generate driver for searches
  def gen_driver(chosen_proxy)
    # Profile settings
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['intl.accept_languages'] = 'en'

    # Set proxy if proxy list, otherwise sleep
    if chosen_proxy
      proxy = Selenium::WebDriver::Proxy.new(http: chosen_proxy, ssl: chosen_proxy)
      profile.proxy = proxy
    else
      sleep(rand(@request_interval[0]..@request_interval[1]))
    end
    
    return Selenium::WebDriver.for :firefox, profile: profile
  end

  # Choose a random proxy that hasn't been used recently
  def get_random_proxy(url)
    max = @proxy_list.length
    chosen = @proxy_list[Random.rand(max)]

    # Only use proxy if it hasn't been used in last n seconds on same host
    if is_not_used?(chosen, url)
      @used_proxies[chosen] = [Time.now, URI.parse(url).host]
      return chosen[0]+":"+chosen[1]
    else
      sleep(0.005)
      get_random_proxy(url)
    end
  end

  # Checks if a proxy has been used on domain in the last 20 seconds
  def is_not_used?(chosen, url)
    return (!@used_proxies[chosen] ||
            @used_proxies[chosen][0] <= Time.now-@request_interval[0] ||
            @used_proxies[chosen][1] != URI.parse(url).host)
  end

  # Parse the proxy list
  def parse_proxy_list(proxy_file)
    if proxy_file
      return IO.readlines(proxy_file).map{ |proxy| proxy.strip.split(":")}
    end
  end
end
