require 'selenium-webdriver'
require 'uri'
require 'pry'


class RequestManager
  def initialize(proxy_list, request_interval, browser_num)
    @proxy_list = parse_proxy_list(proxy_list)
    @request_interval = request_interval
    @used_proxies = Array.new
    @browser_num = browser_num
    @browsers = Hash.new
    open_n_browsers
  end

  # Open the specified number of browsers
  def open_n_browsers
    (1..@browser_num).each do |i|
      open_browser
    end
  end

  # Open the browser with a random proxy
  def open_browser
    chosen_proxy = @proxy_list != nil ? get_random_proxy : nil
    @browsers[chosen_proxy] = [gen_driver(chosen_proxy), Time.now]
  end

  # Get the most recently used browser
  def get_most_recent_browser
    most_recent = @browsers.first
    @browsers.each do |browser|
      if browser[1][1] > most_recent[1][1]
        most_recent = browser
      end
    end

    return most_recent
  end

  # Get the least recently used browser
  def get_least_recent_browser
    least_recent = @browsers.first
    @browsers.each do |browser|
        if browser[1][1] < least_recent[1][1]
          least_recent = browser
        end
    end
    
    # Update the usage time
    @browsers[least_recent[0]] = [least_recent[1][0], Time.now]
    return least_recent[1][0]
  end

  # Restart the browser and open new one
  def restart_browser
    # Get most recently used browser and close it
    close_browser = get_most_recent_browser
    close_browser[1][0].quit

    # Remove it from lists of used browsers and start new
    @browsers.delete(close_browser[0])
    open_browser
    @used_proxies.delete(close_browser[0])
  end

  # Close all the browsers
  def close_all_browsers
    @browsers.each do |browser|
      browser[1][0].quit
    end
  end

  # Get the page requested
  def get_page(url, form_input = nil)
    # Get the page
    browser = get_least_recent_browser
    browser.navigate.to url
    puts "Getting page " + url

    # Handle form input if there is any
    if form_input
      element = driver.find_element(name: "q")
      element.send_keys form_input
      element.submit
    end

    # Sleep while things load then save output
    sleep(rand(@request_interval[0]..@request_interval[1]))
    page_html = browser.page_source
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
  def get_random_proxy
    max = @proxy_list.length
    chosen = @proxy_list[Random.rand(max)]
    chosen_proxy = chosen[0]+":"+chosen[1]
    
    # Only use proxy if it hasn't been used in last n seconds on same host
    if !@used_proxies.include?(chosen_proxy)
      @used_proxies.push(chosen_proxy)
      return chosen_proxy
    else
      sleep(0.005)
      get_random_proxy
    end
  end

  # Parse the proxy list
  def parse_proxy_list(proxy_file)
    if proxy_file
      return IO.readlines(proxy_file).map{ |proxy| proxy.strip.split(":")}
    end
  end
end
