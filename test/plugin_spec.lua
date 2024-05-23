local wc = require('webcomponent-template-editor')

describe('unit tests for webcomponent-template-editor', function()
  it('removes backquotes from array of strings', function()
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
    local result = wc.remove_backquotes(template_literal)
    assert.are.same(template_contents, result)
  end)

  it('adds back backquotes from array of strings', function()
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
    local result = wc.replace_backquotes(template_contents)
    assert.are.same(template_literal, result)
  end)
end)
