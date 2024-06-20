local utils = require('webcomponent-template-editor.utils')
P = function(v)
  print(vim.inspect(v))
  return v
end

local template_literal = {
  '`',
  '      <h1>${this.sayHello(this.name)}!</h1>',
  '      <button @click=${this._onClick} part="button">',
  '        Click Count: ${this.count}',
  '      </bu\n		tton>',
  '      <slot></slot>',
  '    `',
}

local template_contents = {
  '',
  '      <h1>${this.sayHello(this.name)}!</h1>',
  '      <button @click=${this._onClick} part="button">',
  '        Click Count: ${this.count}',
  '      </bu\n		tton>',
  '      <slot></slot>',
  '    ',
}

local template_literal_min = {
  '`<h1>${this.sayHello(this.name)}!</h1>`',
}

local template_contents_min = {
  '<h1>${this.sayHello(this.name)}!</h1>',
}

describe('unit tests for webcomponent-template-editor', function()
  it('removes backquotes from array of strings', function()
    local result = utils.remove_backquotes(template_literal)
    assert.are.same(template_contents, result)
  end)

  it('adds back backquotes from array of strings', function()
    local result = utils.replace_backquotes(template_contents)
    assert.are.same(template_literal, result)
  end)
  it('removes backquotes from array of strings', function()
    local result = utils.remove_backquotes(template_literal_min)
    assert.are.same(template_contents_min, result)
  end)

  it('adds back backquotes from array of strings', function()
    local result = utils.replace_backquotes(template_contents_min)
    assert.are.same(template_literal_min, result)
  end)
end)
