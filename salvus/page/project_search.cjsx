###############################################################################
#
# SageMathCloud: A collaborative web-based interface to Sage, IPython, LaTeX and the Terminal.
#
#    Copyright (C) 2015, Nich Ruhland
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

underscore = require('underscore')

{React, Actions, Store, flux, rtypes, rclass, Flux}  = require('flux')

{Col, Row, Button, Input, Well, Alert} = require('react-bootstrap')
{Icon, Loading, SearchInput, ImmutablePureRenderMixin} = require('r_misc')
misc            = require('misc')
misc_page       = require('misc_page')
{salvus_client} = require('salvus_client')
{PathLink} = require('project_new')


ProjectSearchInput = rclass
    displayName : 'ProjectSearch-ProjectSearchInput'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        user_input : rtypes.string.isRequired
        actions    : rtypes.object.isRequired

    clear_and_focus_input : ->
        @props.actions.setTo
            user_input         : ''
            most_recent_path   : undefined
            command            : undefined
            most_recent_search : undefined
            search_results     : undefined
            search_error       : undefined

        @refs.project_search_input.getInputDOMNode().focus()

    clear_button : ->
        <Button onClick={@clear_and_focus_input}>
            <Icon name='times-circle' />
        </Button>

    handle_change : ->
        user_input = @refs.project_search_input.getValue()
        @props.actions.setTo(user_input : user_input)

    submit : (event) ->
        event.preventDefault()
        @props.actions.search()

    render : ->
        <form onSubmit={@submit}>
            <Input
                ref         = 'project_search_input'
                autoFocus
                type        = 'text'
                placeholder = 'Enter search (supports regular expressions!)'
                value       = {@props.user_input}
                buttonAfter = {@clear_button()}
                onChange    = {@handle_change} />
        </form>

ProjectSearchOutput = rclass
    displayName : 'ProjectSearch-ProjectSearchOutput'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        results          : rtypes.array
        too_many_results : rtypes.bool
        search_error     : rtypes.string
        most_recent_path : rtypes.string
        actions          : rtypes.object.isRequired

    too_many_results : ->
        <Alert bsStyle='warning'>
            There were more results than displayed below. Try making your search more specific.
        </Alert>

    get_results : ->
        if @props.search_error?
            return <Alert bsStyle='warning'>Search error: {@props.search_error} Please
                    try again with a more restrictive search</Alert>
        if @props.results?.length == 0
            return <Alert bsStyle='warning'>There were no results for your search</Alert>
        for i, result of @props.results
                <ProjectSearchResultLine
                    key              = {i}
                    filename         = {result.filename}
                    description      = {result.description}
                    most_recent_path = {@props.most_recent_path}
                    actions          = {@props.actions} />

    render : ->
        results_well_styles =
            backgroundColor : 'white'
            fontFamily      : 'monospace'

        <div>
            {@too_many_results() if @props.too_many_results}
            <Well style={results_well_styles}>
                {@get_results()}
            </Well>
        </div>

ProjectSearchOutputHeader = rclass
    displayName : 'ProjectSearch-ProjectSearchOutputHeader'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        most_recent_path   : rtypes.string.isRequired
        command            : rtypes.string
        most_recent_search : rtypes.string.isRequired
        search_results     : rtypes.array
        info_visible       : rtypes.bool
        search_error       : rtypes.string
        actions            : rtypes.object.isRequired

    getDefaultProps : ->
        info_visible : false

    output_path : ->
        path = @props.most_recent_path
        if path is ''
            return <Icon name='home' />
        return path

    change_info_visible : ->
        @props.actions.setTo(info_visible : not @props.info_visible)

    get_info : ->
        <Alert bsStyle='info'>
            <ul>
                <li>
                    Search command: <kbd>{@props.command}</kbd>
                </li>
                <li>
                    Number of results: {@props.search_error ? @props.search_results?.length ? <Loading />}
                </li>
            </ul>
        </Alert>

    render : ->
        <div style={wordWrap:'break-word'}>
            <span style={color:'#666'}>
                <a href='#project-file-listing'>Navigate to a different folder</a> to search in it.
            </span>

            <h4>
                Results of searching in {@output_path()} for
                "{@props.most_recent_search}" <Button bsStyle='info' bsSize='xsmall' onClick={@change_info_visible}>
                <Icon name='info-circle' /></Button>
            </h4>

            {@get_info() if @props.info_visible}
        </div>

ProjectSearch = rclass
    displayName : 'ProjectSearch'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        current_path       : rtypes.string
        user_input         : rtypes.string
        search_results     : rtypes.array
        search_error       : rtypes.string
        too_many_results   : rtypes.bool
        command            : rtypes.string
        most_recent_search : rtypes.string
        most_recent_path   : rtypes.string
        subdirectories     : rtypes.bool
        case_sensitive     : rtypes.bool
        hidden_files       : rtypes.bool
        info_visible       : rtypes.bool
        actions            : rtypes.object.isRequired

    getDefaultProps : ->
        user_input : ''

    valid_search : ->
        return @props.user_input.trim() isnt ''

    render_output_header : ->
        <ProjectSearchOutputHeader
            most_recent_path   = {@props.most_recent_path}
            command            = {@props.command}
            most_recent_search = {@props.most_recent_search}
            search_results     = {@props.search_results}
            search_error       = {@props.search_error}
            info_visible       = {@props.info_visible}
            actions            = {@props.actions} />

    render_output : ->
        if @props.search_results? or @props.search_error?
            return <ProjectSearchOutput
                most_recent_path = {@props.most_recent_path}
                results          = {@props.search_results}
                too_many_results = {@props.too_many_results}
                search_error     = {@props.search_error}
                actions          = {@props.actions} />
        else if @props.most_recent_search?
            # a search has been made but the search_results or search_error hasn't come in yet
            <Loading />

    render : ->
        <Well>
            <Row>
                <Col sm=8>
                    <Row>
                        <Col sm=9>
                            <ProjectSearchInput
                                user_input = {@props.user_input}
                                actions    = {@props.actions} />
                        </Col>
                        <Col sm=3>
                            <Button bsStyle='primary' onClick={@props.actions.search} disabled={not @valid_search()}>
                                <Icon name='search' /> Search
                            </Button>
                        </Col>
                    </Row>
                    {@render_output_header() if @props.most_recent_search? and @props.most_recent_path?}
                </Col>

                <Col sm=4 style={fontSize:'16px'}>
                    <Input
                        type     = 'checkbox'
                        label    = 'Include subdirectories'
                        checked  = {@props.subdirectories}
                        onChange = {@props.actions.toggle_search_checkbox_subdirectories} />
                    <Input
                        type     = 'checkbox'
                        label    = 'Case sensitive search'
                        checked  = {@props.case_sensitive}
                        onChange = {@props.actions.toggle_search_checkbox_case_sensitive} />
                    <Input
                        type     = 'checkbox'
                        label    = 'Include hidden files'
                        checked  = {@props.hidden_files}
                        onChange = {@props.actions.toggle_search_checkbox_hidden_files} />
                </Col>
            </Row>
            <Row>
                <Col sm=12>
                    {@render_output()}
                </Col>
            </Row>
        </Well>

ProjectSearchResultLine = rclass
    displayName : 'ProjectSearch-ProjectSearchResultLine'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        filename         : rtypes.string
        description      : rtypes.string
        most_recent_path : rtypes.string
        actions          : rtypes.object.isRequired

    click_filename : (e) ->
        e.preventDefault()
        @props.actions.open_file
            path       : misc.path_to_file(@props.most_recent_path, @props.filename)
            foreground : misc_page.open_in_foreground(e)

    render : ->
        <div style={wordWrap:'break-word'}>
            <a onClick={@click_filename} href=''><strong>{@props.filename}</strong></a>
            <span style={color:'#666'}> {@props.description}</span>
        </div>

ProjectSearchHeader = rclass
    displayName : 'ProjectSearch-ProjectSearchHeader'

    mixins: [ImmutablePureRenderMixin]

    propTypes :
        current_path : rtypes.string
        actions      : rtypes.object.isRequired

    render : ->
        <h1>
            <Icon name='search' /> Search <span className='hidden-xs'> in <PathLink path={@props.current_path} actions={@props.actions} /></span>
        </h1>

render = (project_id, flux) ->
    store = flux.getProjectStore(project_id)
    actions = flux.getProjectActions(project_id)
    header_connect_to =
        current_path : store.name

    search_connect_to =
        current_path       : store.name
        user_input         : store.name
        search_results     : store.name
        search_error       : store.name
        too_many_results   : store.name
        command            : store.name
        most_recent_search : store.name
        most_recent_path   : store.name
        subdirectories     : store.name
        case_sensitive     : store.name
        hidden_files       : store.name
        info_visible       : store.name

    <div>
        <Row>
            <Col sm=12>
                <Flux flux={flux} connect_to={header_connect_to}>
                    <ProjectSearchHeader actions={actions} />
                </Flux>
            </Col>
        </Row>
        <Row>
            <Col sm=12>
                <Flux flux={flux} connect_to={search_connect_to}>
                    <ProjectSearch actions={actions}/>
                </Flux>
            </Col>
        </Row>
    </div>

exports.render_project_search = (project_id, dom_node, flux) ->
    React.render(render(project_id, flux), dom_node)


exports.unmount = (dom_node) ->
    #console.log("unmount project_search")
    React.unmountComponentAtNode(dom_node)
