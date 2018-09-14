=begin
Insights Service Catalog API

This is a API to fetch and order catalog items from different cloud sources

OpenAPI spec version: 1.0.0
Contact: you@your-company.com
Generated by: https://github.com/swagger-api/swagger-codegen.git

=end
class AdminsController < ApplicationController

  def add_portfolio
    portfolio = Portfolio.create(:name        => params[:name],
                                 :description => params[:description],
                                 :image_url   => params[:url],
                                 :enabled     => params[:enabled])
    render json: portfolio
  end

  def list_portfolios
    portfolios = Portfolio.all
    render json: portfolios
  end

  def fetch_portfolio_with_id
    item = Portfolio.where(:id => params[:portfolio_id]).first
    render json: item
  end

  def fetch_portfolio_items_with_portfolio
    portfolio_items = Portfolio.where(id: params[:portfolio_id]).first
                               .portfolio_items
    render json: portfolio_items
  end

  def fetch_portfolio_item_from_portfolio
    portfolio_item = Portfolio.where(id: params[:portfolio_id], porfolio_item_id: params[:portfolio_item_id])
                              .includes(:portfolio_items)
    render json: portfolio_item
  end

  def add_portfolio_item_with_portfolio
    portfolio = Portfolio.where(id: params[:portfolio_id]).first
    portfolio_item = PortfolioItem.where(id: params[:portfolio_item_id]).first
    portfolio << portfolio_item
    render json: portfolio_item
  end

  def add_portfolio_item
    portfolio_item = PortfolioItem.create!(
        favorite: params[:favorite],
        name: params[:name],
        description: params[:description],
        orphan: params[:orphan],
        state: params[:state]
    )
    render json: portfolio_item
  end

  def list_portfolio_items
    portfolio_items = PortfolioItem.all
    render json: portfolio_items
  end
end